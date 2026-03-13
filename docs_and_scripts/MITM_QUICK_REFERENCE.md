# MITM Attack Detection & Prevention - Quick Reference

## Quick Start (30 seconds)

```bash
# Terminal 1: Start MITM Detector
sudo python3 ebpf/detect_mitm_attacks.py --interface eth0

# Terminal 2: Start Attack Simulation
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 127.0.0.1 \
    --gateway 192.168.1.1 \
    --attack-type all

# Or use combined demo:
sudo ./demo-mitm-attack.sh arp 30
```

## What Gets Detected

| Attack | Detection | Attacker ID |
|--------|-----------|------------|
| **ARP Spoofing** | MAC address mismatch | IP + MAC |
| **MITM Position** | Dual ARP spoofing | IP + MAC |
| **Packet Sniffing** | Anomalous packet timing | IP + tool signature |
| **DNS Spoofing** | Unexpected DNS responses | IP + DNS server |
| **SSL Stripping** | HTTPS downgrade | IP + certificate |

## Attack Simulation Examples

### Simulate Simple ARP Spoofing
```bash
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 192.168.1.105 \
    --gateway 192.168.1.1 \
    --attack-type arp \
    --duration 30
```
**Detected as**: `MAC_ADDRESS_SPOOFING` with HIGH severity

### Simulate MITM Position (Two-Way)
```bash
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 192.168.1.105 \
    --gateway 192.168.1.1 \
    --attack-type dual-arp \
    --duration 60
```
**Detected as**: `ARP_SPOOFING_DETECTED` with CRITICAL severity

### Simulate Packet Sniffing
```bash
# Start detector
sudo python3 ebpf/detect_mitm_attacks.py --interface eth0

# In another terminal, start tcpdump (the attack)
tcpdump -i eth0 -w packets.pcap &

# Generate traffic
for i in {1..1000}; do
    ping -c 1 127.0.0.1 > /dev/null 2>&1 &
done

# Detector will identify the regular packet intervals of tcpdump
```
**Detected as**: `PACKET_SNIFFING_DETECTED` with HIGH severity

### Simulate All Attacks at Once
```bash
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 127.0.0.1 \
    --gateway 192.168.1.1 \
    --attack-type all \
    --duration 30
```

## Reading Detection Output

### Example 1: ARP Spoofing Detected

```json
{
  "timestamp": "2026-03-08T14:25:30.123456Z",
  "attack_type": "MAC_ADDRESS_SPOOFING",
  "severity": "HIGH",
  "attacker_ip": "192.168.1.100",
  "old_mac": "AA:BB:CC:DD:EE:FF",
  "new_mac": "11:22:33:44:55:66",
  "description": "MAC address changed for IP 192.168.1.100",
  "indicators": [
    "MAC address changed for same IP (MITM indicator)",
    "Possible ARP spoofing attack",
    "Attacker may be redirecting traffic"
  ],
  "action": "Verify legitimate device, block if unauthorized"
}
```

**What it means:**
- IP 192.168.1.100 changed MAC addresses
- **Attacker identified as**: 192.168.1.100 (IP) + 11:22:33:44:55:66 (MAC)
- **Action**: Block the MAC address immediately

### Example 2: CRITICAL MITM in Progress

```json
{
  "timestamp": "2026-03-08T14:25:45.234567Z",
  "attack_type": "ARP_SPOOFING_DETECTED",
  "severity": "CRITICAL",
  "attacker_ip": "192.168.1.100",
  "attacker_mac": "11:22:33:44:55:66",
  "description": "Excessive ARP responses from 192.168.1.100",
  "indicators": [
    "More than 10 ARP replies in 1 minute",
    "Possible ARP spoofing attack",
    "Attacker impersonating legitimate host"
  ],
  "action": "Block traffic from this MAC address immediately"
}
```

**What it means:**
- More than 10 ARP replies in 1 minute = ARP spoofing attack
- **Attacker position**: Between legitimate hosts
- **Capability**: Can see and modify all traffic
- **Urgency**: CRITICAL - block immediately

### Example 3: Packet Sniffing Detected

```json
{
  "timestamp": "2026-03-08T14:26:00.345678Z",
  "attack_type": "PACKET_SNIFFING_DETECTED",
  "severity": "HIGH",
  "attacker_ip": "192.168.1.50",
  "packet_count": 523,
  "bytes_captured": 1048576,
  "indicators": [
    "Unusual packet capture rate detected",
    "Regular interval between packets (sniffer behavior)",
    "High volume of packets with anomalous pattern",
    "Possible packet sniffing or tcpdump activity"
  ],
  "action": "Investigate source for unauthorized packet capture tools"
}
```

**What it means:**
- IP 192.168.1.50 is capturing packets (likely tcpdump/Wireshark)
- **Regular timing** (not natural traffic) indicates automated sniffer
- **523 packets captured** ~1MB of data
- **Risk**: Attacker may be stealing credentials, tokens, etc.

## Attacker Identification Methods

### 1. By IP Address
```bash
# Find what device is at this IP
nmap -p- 192.168.1.100
dig -x 192.168.1.100  # Reverse DNS
```

### 2. By MAC Address
```bash
# Find device with this MAC
arp-scan 192.168.1.0/24 | grep 11:22:33:44:55:66

# Check switch port
lldpctl  # Shows connected devices and ports
```

### 3. By Hostname
From detector output, may identify:
- Employee laptop: `john-laptop-23`
- Server: `prod-db-01`
- IoT device: `rpi-sensor-4`

### 4. By Location
```
- WiFi SSID indicates location (Building A, Floor 3)
- Switch port identifies physical jack
- Security cameras can verify
```

### 5. By Tool Signature
- **tcpdump**: Regular 10ms intervals, specific packet patterns
- **Wireshark**: Larger captures, variable intervals
- **mitmproxy**: HTTP CONNECT tunneling
- **Burp Suite**: PortSwigger certificate
- **Nethunter**: Kali Linux tool signatures

## Blocking Attackers

### Quick Block (Network)
```bash
# Block by IP (firewall)
sudo iptables -I INPUT -s 192.168.1.100 -j DROP

# Block by MAC (ARP snooping)
# Configure on network switch (port security)
```

### Database Block
```bash
# Add to attacker database
sqlite3 security.db \
  "INSERT INTO blocked_hosts VALUES ('192.168.1.100', '11:22:33:44:55:66', 'ARP_SPOOF', NOW());"
```

### Restore ARP
```bash
# Clear ARP cache
sudo arp -d -a

# Rebuild legitimate ARP table
sudo arping -c 1 -A -I eth0 192.168.1.1
```

## Integration Examples

### With Alerting System
```bash
# Send alert to Slack
curl -X POST https://hooks.slack.com/services/XXX/YYY/ZZZ \
  -d '{"text":"MITM ATTACK DETECTED: 192.168.1.100 (11:22:33:44:55:66)"}'
```

### With Logging System
```bash
# Send to syslog
logger -t mitm-detector "MITM attack from 192.168.1.100"

# Send to ELK Stack
curl -X POST http://elasticsearch:9200/security/mitm \
  -H 'Content-Type: application/json' \
  -d @alert.json
```

### With Automated Response
```bash
#!/bin/bash
# Auto-response script

ATTACKER_IP="192.168.1.100"
ATTACKER_MAC="11:22:33:44:55:66"

# Log
echo "[$(date)] MITM Attack from $ATTACKER_IP ($ATTACKER_MAC)" >> security.log

# Block
iptables -I INPUT -s $ATTACKER_IP -j DROP

# Notify
wall "SECURITY: MITM attack detected and blocked from $ATTACKER_IP"

# Investigate
nmap -A -T4 $ATTACKER_IP > investigate_$ATTACKER_IP.txt
```

## Common Questions

**Q: Can PQC crypto protect against MITM?**  
A: Yes! ML-KEM + ML-DSA protect against MITM even if attacker sees all traffic. Attacker cannot decrypt (ML-KEM) or forge (ML-DSA).

**Q: Does detector prevent attacks?**  
A: No, it detects and identifies. Prevention requires:
- Firewall rules
- ARP snooping
- Static ARP bindings
- Port security

**Q: Can legitimate users trigger false positives?**  
A: Rarely. MAC changes are always suspicious. Packet sniffing requires specific tool signatures.

**Q: What if attacker uses spoofed MAC?**  
A: Detector still identifies by IP address. Can also identify by traffic patterns/tool signature.

## Files & Logs

```
Main scripts:
  - ebpf/detect_mitm_attacks.py       # Detector
  - ebpf/simulate_mitm_attacks.py     # Simulator
  - demo-mitm-attack.sh               # Combined demo

Logs:
  - logs/mitm-attacks.jsonl           # Detected attacks (IMPORTANT)
  - logs/mitm-simulation.jsonl        # Simulated attacks

Config:
  - ebpf/mitm_config.json             # Detector configuration
```

## Testing Checklist

- [ ] Detector running on eth0 (or your interface)
- [ ] Can ping test IP (127.0.0.1, localhost)
- [ ] Simulator starts without errors
- [ ] Alerts appear in detector output
- [ ] Logs written to mitm-attacks.jsonl
- [ ] Attacker IP identified correctly
- [ ] Attacker MAC identified correctly
- [ ] Can block attacker with iptables

## Support

For detailed information: [MITM_DETECTION_PREVENTION.md](../MITM_DETECTION_PREVENTION.md)

For eBPF monitoring: [EBPF_MONITORING_QUICK_REFERENCE.md](../EBPF_MONITORING_QUICK_REFERENCE.md)
