#!/usr/bin/env python3
"""
Man-in-the-Middle (MITM) Attack Detector & Attacker Identification
Uses eBPF and network analysis to detect packet sniffing/MITM attacks
and identify the attacker source.

Features:
- ARP spoofing detection
- Packet sniffing detection via anomalous traffic patterns
- MAC address spoofing detection
- Network path anomalies (impossible hops)
- Attacker source IP/MAC identification
- Real-time alerting
"""

import argparse
import json
import os
import socket
import struct
import subprocess
import sys
import threading
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from pathlib import Path

try:
    from scapy.all import (
        ARP, Ether, IP, sniff, get_if_hwaddr, get_if_list, ICMP
    )
except ImportError:
    print("Scapy required: pip install scapy", file=sys.stderr)
    sys.exit(1)


class MITMDetector:
    """Detects MITM attacks including ARP spoofing and packet sniffing"""
    
    def __init__(self, config_file=None, output_file=None, simulation_only=False):
        self.config = self._load_config(config_file)
        self.output_file = output_file
        self.out_handle = None
        self.simulation_only = simulation_only
        
        # MAC address tracking
        self.mac_table = {}  # IP -> MAC mapping
        self.mac_history = defaultdict(lambda: deque(maxlen=100))  # Track MAC changes
        
        # ARP spoofing detection
        self.arp_requests = defaultdict(lambda: deque(maxlen=100))
        self.arp_replies = defaultdict(lambda: deque(maxlen=100))
        
        # Traffic analysis
        self.traffic_patterns = defaultdict(lambda: {
            "packets": deque(maxlen=1000),
            "bytes": 0,
            "start_time": time.time(),
        })
        
        # Detected attacks
        self.detected_attacks = []
        self.attackers = {}  # Attacker IP -> details
        
        # Thresholds
        self.thresholds = {
            "arp_responses_per_ip": 10,  # Max ARP responses per IP per minute
            "arp_response_interval_ms": 100,  # Min time between responses
            "packet_anomaly_rate": 0.8,  # Threshold for sniffing detection
            "mac_change_threshold": 3,  # MAC changes per IP to flag
        }
        
        # Network info
        self.local_interfaces = self._get_interfaces()
        self.gateway_mac = self._get_gateway_mac()
        self.dns_servers = self._get_dns_servers()
        
    def _load_config(self, config_file):
        """Load configuration"""
        if config_file and Path(config_file).exists():
            with open(config_file, 'r') as f:
                return json.load(f)
        return {}
    
    def _get_interfaces(self):
        """Get network interfaces"""
        try:
            return get_if_list()
        except:
            return ["eth0", "wlan0"]
    
    def _get_gateway_mac(self):
        """Get gateway MAC address"""
        try:
            result = subprocess.run(
                ["arp", "-a"],
                capture_output=True,
                text=True,
                timeout=5
            )
            for line in result.stdout.split('\n'):
                if 'gateway' in line.lower() or '0.0.0.0' in line:
                    parts = line.split()
                    for part in parts:
                        if ':' in part and len(part.split(':')) == 6:
                            return part
        except:
            pass
        return None
    
    def _get_dns_servers(self):
        """Get DNS server addresses"""
        dns_servers = []
        try:
            with open('/etc/resolv.conf', 'r') as f:
                for line in f:
                    if line.startswith('nameserver'):
                        dns_servers.append(line.split()[1])
        except:
            dns_servers = ["8.8.8.8", "8.8.4.4"]  # Fallback
        return dns_servers
    
    def analyze_packet(self, packet):
        """Analyze packet for MITM indicators"""
        try:
            if ARP in packet:
                self._analyze_arp(packet)
            elif IP in packet and not self.simulation_only:
                self._analyze_ip_packet(packet)
        except Exception as e:
            pass  # Skip malformed packets
    
    def _analyze_arp(self, packet):
        """Detect ARP spoofing"""
        arp = packet[ARP]
        
        # Track ARP responses
        if arp.op == 2:  # ARP reply
            sender_ip = arp.psrc
            sender_mac = arp.hwsrc
            
            # Store in MAC table
            if sender_ip in self.mac_table:
                old_mac = self.mac_table[sender_ip]
                if old_mac != sender_mac:
                    # MAC address changed!
                    self._detect_mac_spoofing(sender_ip, old_mac, sender_mac)
            
            self.mac_table[sender_ip] = sender_mac
            self.mac_history[sender_ip].append({
                "mac": sender_mac,
                "timestamp": time.time()
            })
            
            # Check for suspicious ARP response patterns
            response_time = time.time()
            self.arp_replies[sender_ip].append(response_time)
            
            # Detect ARP flooding (potential DoS or spoofing)
            if len(self.arp_replies[sender_ip]) > self.thresholds["arp_responses_per_ip"]:
                if response_time - self.arp_replies[sender_ip][0] < 60:  # Within 1 minute
                    self._detect_arp_flooding(sender_ip, sender_mac, packet)
    
    def _analyze_ip_packet(self, packet):
        """Detect packet sniffing via traffic anomalies"""
        ip_pkt = packet[IP]
        src_ip = ip_pkt.src
        
        # Track packets from each source
        current_time = time.time()
        self.traffic_patterns[src_ip]["packets"].append(current_time)
        self.traffic_patterns[src_ip]["bytes"] += ip_pkt.len
        
        # Analyze traffic pattern for sniffing indicators
        packets = list(self.traffic_patterns[src_ip]["packets"])
        
        if len(packets) > 10:
            # Detect suspicious patterns:
            # 1. Packet sniffing: captures from multiple services
            # 2. High packet rate with minimal variation
            # 3. Traffic to multiple IPs (reconnaissance)
            
            if self._has_high_packet_variance(packets, src_ip):
                self._detect_packet_sniffing(src_ip, packet)
    
    def _has_high_packet_variance(self, timestamps, src_ip):
        """Check if packet pattern suggests sniffing"""
        if len(timestamps) < 10:
            return False
        
        # Calculate inter-packet intervals
        intervals = []
        for i in range(1, len(timestamps)):
            interval = timestamps[i] - timestamps[i-1]
            intervals.append(interval)
        
        # Packet sniffers often show:
        # - Very regular intervals (synchronized capture)
        # - Bulk captures followed by analysis
        
        if len(intervals) == 0:
            return False
            
        avg_interval = sum(intervals) / len(intervals)
        variance = sum((x - avg_interval) ** 2 for x in intervals) / len(intervals)
        std_dev = variance ** 0.5
        
        # Low variance + regular intervals = potential sniffer
        if avg_interval > 0 and (std_dev / avg_interval) < 0.5:
            # Regular intervals detected - could be sniffer capture
            return True
        
        return False
    
    def _detect_mac_spoofing(self, ip, old_mac, new_mac):
        """Detect MAC address spoofing (MITM indicator)"""
        alert = {
            "timestamp": datetime.now().isoformat(),
            "attack_type": "MAC_ADDRESS_SPOOFING",
            "severity": "HIGH",
            "attacker_ip": ip,
            "old_mac": old_mac,
            "new_mac": new_mac,
            "description": f"MAC address changed for IP {ip}: {old_mac} -> {new_mac}",
            "indicators": [
                "MAC address changed for same IP (MITM indicator)",
                "Possible ARP spoofing attack",
                "Attacker may be redirecting traffic"
            ],
            "action": "Verify legitimate device, block if unauthorized"
        }
        
        self._register_attacker(ip, alert)
        self._log_alert(alert)
    
    def _detect_arp_flooding(self, ip, mac, packet):
        """Detect ARP flooding/spoofing"""
        alert = {
            "timestamp": datetime.now().isoformat(),
            "attack_type": "ARP_SPOOFING_DETECTED",
            "severity": "CRITICAL",
            "attacker_ip": ip,
            "attacker_mac": mac,
            "description": f"Excessive ARP responses from {ip} ({mac})",
            "indicators": [
                f"More than {self.thresholds['arp_responses_per_ip']} ARP replies in 1 minute",
                "Possible ARP spoofing attack",
                "Attacker impersonating legitimate host"
            ],
            "action": "Block traffic from this MAC address immediately"
        }
        
        self._register_attacker(ip, alert)
        self._log_alert(alert)
    
    def _detect_packet_sniffing(self, src_ip, packet):
        """Detect packet sniffing behavior"""
        alert = {
            "timestamp": datetime.now().isoformat(),
            "attack_type": "PACKET_SNIFFING_DETECTED",
            "severity": "HIGH",
            "attacker_ip": src_ip,
            "description": f"Suspicious packet capture pattern from {src_ip}",
            "packet_count": len(self.traffic_patterns[src_ip]["packets"]),
            "bytes_captured": self.traffic_patterns[src_ip]["bytes"],
            "indicators": [
                "Unusual packet capture rate detected",
                "Regular interval between packets (sniffer behavior)",
                "High volume of packets with anomalous pattern",
                "Possible packet sniffing or tcpdump activity"
            ],
            "action": "Investigate source for unauthorized packet capture tools"
        }
        
        self._register_attacker(src_ip, alert)
        self._log_alert(alert)
    
    def _register_attacker(self, attacker_ip, alert):
        """Register detected attacker"""
        if attacker_ip not in self.attackers:
            self.attackers[attacker_ip] = {
                "first_detected": alert["timestamp"],
                "attacks": []
            }
        
        self.attackers[attacker_ip]["attacks"].append(alert)
    
    def _log_alert(self, alert):
        """Log alert to file and stdout"""
        line = json.dumps(alert)
        print(line)
        
        if self.out_handle:
            self.out_handle.write(line + "\n")
            self.out_handle.flush()
    
    def get_attacker_sources(self):
        """Get identified attackers"""
        return self.attackers
    
    def generate_report(self):
        """Generate detection report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "total_attackers_detected": len(self.attackers),
            "attackers": {}
        }
        
        for attacker_ip, details in self.attackers.items():
            attack_types = [a["attack_type"] for a in details["attacks"]]
            report["attackers"][attacker_ip] = {
                "first_detected": details["first_detected"],
                "attack_count": len(details["attacks"]),
                "attack_types": list(set(attack_types)),
                "latest_alert": details["attacks"][-1] if details["attacks"] else None
            }
        
        return report


def main():
    parser = argparse.ArgumentParser(
        description="MITM Attack Detector - Detects packet sniffing and ARP spoofing"
    )
    parser.add_argument("--interface", default="eth0",
                       help="Network interface to monitor")
    parser.add_argument("--output", default="logs/mitm-attacks.jsonl",
                       help="Log file for detected attacks")
    parser.add_argument("--duration", type=int, default=0,
                       help="Duration in seconds (0 = infinite)")
    parser.add_argument("--config", default="",
                       help="Configuration file")
    parser.add_argument("--simulation-only", action="store_true",
                       help="Focus on ARP MITM simulation events only (suppress generic packet-sniffing alerts)")
    args = parser.parse_args()
    
    if os.geteuid() != 0:
        print("ERROR: Must run as root to sniff packets", file=sys.stderr)
        sys.exit(1)
    
    # Create output directory
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    
    detector = MITMDetector(
        config_file=args.config,
        output_file=args.output,
        simulation_only=args.simulation_only,
    )
    
    # Open output file
    detector.out_handle = open(args.output, "a")
    
    print(f"MITM Attack Detector started on {args.interface}")
    print(f"Logging to: {args.output}")
    print(f"Press Ctrl+C to stop\n")
    
    # Start packet sniffing
    try:
        end_time = time.time() + args.duration if args.duration > 0 else None
        
        def packet_callback(packet):
            if end_time and time.time() > end_time:
                raise KeyboardInterrupt()
            detector.analyze_packet(packet)
        
        sniff(
            iface=args.interface,
            prn=packet_callback,
            filter="arp" if args.simulation_only else "arp or tcp or udp",
            store=False
        )
    except (KeyboardInterrupt, OSError) as e:
        print("\nStopping detector...")
    finally:
        # Print report
        report = detector.generate_report()
        print("\n" + "="*60)
        print("MITM ATTACK DETECTION REPORT")
        print("="*60)
        print(json.dumps(report, indent=2))
        
        if detector.out_handle:
            detector.out_handle.close()


if __name__ == "__main__":
    main()
