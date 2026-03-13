# Man-in-the-Middle (MITM) Attack Detection & Prevention Guide

## Table of Contents

1. [Overview](#overview)
2. [MITM Attack Types](#mitm-attack-types)
3. [Detection Mechanisms](#detection-mechanisms)
4. [Attacker Identification](#attacker-identification)
5. [Quick Start](#quick-start)
6. [Running Simulations](#running-simulations)
7. [Interpreting Results](#interpreting-results)
8. [Prevention Strategies](#prevention-strategies)
9. [Real-World Deployment](#real-world-deployment)

---

## Overview

A Man-in-the-Middle (MITM) attack occurs when an attacker intercepts communication between two parties without their knowledge. This guide shows how to detect, identify, and prevent MITM attacks in your SIA_BANK microservices architecture.

### Attack Scenarios Covered

| Attack | Detection Method | Attacker ID |
|--------|------------------|-----------|
| **ARP Spoofing** | MAC address tracking, ARP flooding | Source IP + MAC |
| **DNS Spoofing** | DNS query analysis | IP + DNS server |
| **SSL Stripping** | TLS downgrade detection | Session tracking |
| **Packet Sniffing** | Traffic pattern analysis | Pcap signatures |
| **Session Hijacking** | Token anomaly detection | Network fingerprint |

---

## MITM Attack Types

### 1. ARP Spoofing (Address Resolution Protocol)

**How it works:**
```
Normal:  Client → Gateway (via ARP: "Who has 192.168.1.1?")
         Gateway responds: "I am 192.168.1.1, my MAC is AA:BB:CC:DD:EE:FF"
         Client trusts and sends traffic to that MAC

MITM:    Attacker spoofs ARP response claiming to BE the gateway
         Attacker says: "I am 192.168.1.1, my MAC is 11:22:33:44:55:66"
         Client redirects traffic to attacker instead of real gateway
         Attacker can now:
         - Intercept and read all traffic
         - Modify packets
         - Perform DNS spoofing
```

**Detection Indicators:**
- Multiple MAC addresses claiming to be same IP
- Rapid ARP response rate (flooding)
- MAC address changes for known devices

### 2. Packet Sniffing

**How it works:**
```
Attacker runs tcpdump or Wireshark:
- Listens to all packets on network segment
- Captures unencrypted authentication tokens
- Extracts sensitive data
- May do this passively (no spoofing needed)
```

**Detection Indicators:**
- Unusual Inter-Packet arrival patterns
- Low variance in capture intervals (regular timing)
- High packet capture rate from single source
- Tool signatures (tcpdump, Wireshark)

### 3. DNS Spoofing

**How it works:**
```
1. User types: https://bank.example.com
2. User's computer queries DNS for IP
3. Attacker intercepts DNS query
4. Attacker responds with fake IP (attacker's server)
5. User connects to attacker's server thinking it's the bank
6. Attacker either:
   - Shows fake login page (phishing)
   - Proxies traffic (sees what user sends)
   - Strips SSL (downgrades HTTPS to HTTP)
```

**Detection Indicators:**
- DNS response from unexpected source
- DNS response comes before legitimate DNS server response
- Domain name mismatches

### 4. SSL Stripping

**How it works:**
```
1. User types: https://bank.example.com
2. Attacker intercepts the request
3. Changes HTTPS to HTTP (sends to attacker's proxy)
4. User inadvertently connects via HTTP
5. Attacker then connects to real server via HTTPS (to user, appears secure)
6. User thinks they're on secure HTTPS but actually using unencrypted HTTP
```

**Detection Indicators:**
- HTTPS requests being downgraded to HTTP
- Certificate pinning violations
- Missing HSTS headers

### 5. Session Hijacking

**How it works:**
```
1. Legitimate user logs in, gets session token
2. Attacker captures this token (via sniffing or XSS)
3. Attacker uses the stolen token to impersonate user
4. Can make transactions, change passwords, etc.
```

**Detection Indicators:**
- Session token used from different IP
- Impossible travel (same user in different locations too quickly)
- Unusual session activity patterns

---

## Detection Mechanisms

### Detection Method 1: MAC Address Tracking

```python
# Track IP to MAC mapping
Known: 192.168.1.1 → AA:BB:CC:DD:EE:FF (Gateway)

Spoofing Event:
  New ARP response: 192.168.1.1 → 11:22:33:44:55:66

Detection: ALERT - MAC address changed for same IP!
Verdict: ARP spoofing attempt
Attacker: 11:22:33:44:55:66 (attacker's MAC)
```

### Detection Method 2: ARP Flood Detection

```python
# Count ARP responses per IP per minute
Legitimate gateway: ~2-3 ARP responses/min

Spoofing attack: 50+ ARP responses/min

Detection: ALERT - Excessive ARP responses
Verdict: ARP flooding/spoofing attack
Attacker: Source IP of ARP packets
```

### Detection Method 3: Traffic Pattern Analysis

```python
# Analyze inter-packet arrival times
Legitimate user: Random intervals (5ms, 15ms, 2ms, 8ms...)
               Variance = High, Std Dev = High

Packet sniffer: Regular intervals (10ms, 10ms, 10ms, 10ms...)
              Variance = Low, Std Dev ≈ 0
              (indicates tcpdump/Wireshark capture loop)

Detection: ALERT - Unusual packet capture pattern
Verdict: Packet sniffing attempt
Attacker: Source IP of sniff traffic
```

### Detection Method 4: Certificate Analysis

```python
# Monitor TLS certificates presented
Expected: Certificate issued by trusted CA, matches domain
         Valid dates, not expired

MITM attack: 
  - Self-signed cert (SSL strip)
  - Cert for different domain
  - Cert from different CA (Fiddler, Burp Suite)

Detection: ALERT - Certificate mismatch detected
Verdict: SSL interception/stripping attempt
Attacker: IP presenting fake certificate
```

---

## Attacker Identification

### How We Identify the Attacker

#### 1. **Source IP Address**
The IP where malicious packets originate
```
Example: Attacker at 192.168.1.100 sends spoofed ARP
Detection identifies: 192.168.1.100 as the attacker
```

#### 2. **MAC Address**
The hardware address of the NIC sending attack packets
```
Example: Attacker's MAC = 11:22:33:44:55:66
Detected in ARP replies claiming to be 192.168.1.1
```

#### 3. **Hostname/Device Name**
If we can resolve the IP to a hostname
```
Example: attacker.corp.local
Or: employee-laptop-23
```

#### 4. **Network Fingerprint**
Characteristics of attacker's packets:
- TTL values
- TCP window sizes
- TCP options
- MTU size
Can identify OS (Windows/Linux/Mac) and sometimes tool used

#### 5. **Temporal Analysis**
When did the attack start and stop?
```
Attack window: 2026-03-08 14:23:45 to 14:35:22 UTC
Duration: ~12 minutes
Suggests: Limited-time attack (brief sniffing session)
```

#### 6. **Tool Signature**
Detect if specific hacking/sniffing tools are used:
- **tcpdump**: Regular packet intervals, specific packet size patterns
- **Wireshark**: Similar to tcpdump, larger captures
- **mitmproxy**: HTTP CONNECT tunneling, certificate substitution
- **Burp Suite**: SSL certificate issued by PortSwigger
- **ettercap**: ARP spoofing with specific patterns

### Identification Example

```json
{
  "attack_type": "ARP_SPOOFING",
  "timestamp": "2026-03-08T14:23:45Z",
  "attacker_info": {
    "ip_address": "192.168.1.100",
    "mac_address": "11:22:33:44:55:66",
    "hostname": "employee-laptop-23",
    "os_estimate": "Linux (TTL=64)",
    "tool_signature": "tcpdump (packet interval variance < 0.5)",
    "network_location": "Building A, Floor 3 (based on WiFi SSID)",
    "first_detected": "2026-03-08T14:23:45Z",
    "last_detected": "2026-03-08T14:35:22Z",
    "attack_duration_minutes": 12,
    "confidence": "HIGH"
  },
  "evidence": [
    "ARP flooding: 50+ responses/minute from 192.168.1.100",
    "MAC mismatch: IP 192.168.1.1 now resolves to 11:22:33:44:55:66",
    "Spoofed gateway: Claims to be 192.168.1.1",
    "Regular packet intervals: 10ms ± 2ms (tcpdump signature)"
  ],
  "recommended_actions": [
    "Block 192.168.1.100 at network edge",
    "Block MAC 11:22:33:44:55:66",
    "Investigate device at physical location",
    "Review system logs on 192.168.1.100",
    "Change gateway MAC binding in DHCP"
  ]
}
```

---

## Quick Start

### Installation

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y python3-pip arp-scan tcpdump

# Install Python packages
pip3 install scapy
```

### Run MITM Attack Detection

```bash
# Start detector (monitors for attacks)
sudo python3 ebpf/detect_mitm_attacks.py \
    --interface eth0 \
    --output logs/mitm-attacks.jsonl \
    --duration 300

# In another terminal, simulate attacks
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 127.0.0.1 \
    --gateway 192.168.1.1 \
    --attack-type all \
    --duration 30
```

### Combined Demo

```bash
sudo ./demo-mitm-attack.sh arp 30
```

---

## Running Simulations

### Scenario 1: Simple ARP Spoofing

```bash
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 192.168.1.105 \
    --gateway 192.168.1.1 \
    --attack-type arp \
    --duration 30
```

**What happens:**
1. Attacker sends ARP replies claiming to be gateway
2. Target redirects traffic to attacker
3. Detector identifies MAC mismatch and flags attacker

**Expected output:**
```json
{
  "attack_type": "MAC_ADDRESS_SPOOFING",
  "severity": "HIGH",
  "attacker_ip": "192.168.1.100",
  "old_mac": "AA:BB:CC:DD:EE:FF",
  "new_mac": "11:22:33:44:55:66",
  "indicators": ["MAC address changed for same IP"]
}
```

### Scenario 2: Man-in-the-Middle Position

```bash
sudo python3 ebpf/simulate_mitm_attacks.py \
    --target 192.168.1.105 \
    --gateway 192.168.1.1 \
    --attack-type dual-arp \
    --duration 30
```

**What happens:**
1. Attacker spoofs both sides (target and gateway)
2. All traffic flows through attacker
3. Attacker can now:
   - Read encrypted traffic (PQC still protects!)
   - Inject fake packets
   - Perform DNS spoofing

### Scenario 3: Packet Sniffing + MITM

```bash
# Terminal 1: Start packet sniffer (attacker)
tcpdump -i eth0 -w captured_packets.pcap &

# Terminal 2: Start detector
sudo python3 ebpf/detect_mitm_attacks.py --interface eth0

# Terminal 3: Generate traffic
for i in {1..100}; do
    curl http://localhost:8081/api/account 2>/dev/null
    sleep 0.1
done
```

**Detection:** Detector identifies regular packet intervals characteristic of tcpdump.

---

## Interpreting Results

### Alert Levels

| Severity | Meaning | Action |
|----------|---------|--------|
| CRITICAL | Active MITM in progress | Block immediately |
| HIGH | Strong MITM indicators | Investigate and block |
| MEDIUM | Possible MITM attack | Monitor closely |
| LOW | Suspicious patterns | Log for review |

### Sample Alert Interpretation

```json
{
  "timestamp": "2026-03-08T14:25:30.123456Z",
  "attack_type": "ARP_SPOOFING_DETECTED",
  "severity": "CRITICAL",
  "attacker_ip": "192.168.1.100",
  "attacker_mac": "11:22:33:44:55:66",
  "description": "Excessive ARP responses from 192.168.1.100 (11:22:33:44:55:66)",
  "indicators": [
    "More than 10 ARP replies in 1 minute",
    "Possible ARP spoofing attack",
    "Attacker impersonating legitimate host"
  ],
  "action": "Block traffic from this MAC address immediately"
}
```

**What it means:**
- Attacker at 192.168.1.100 is sending many ARP replies
- This is classic ARP spoofing / MITM setup
- The attacker is identified by both IP and MAC
- Immediate blocking recommended

---

## Prevention Strategies

### 1. Network Level

#### Static ARP Bindings
```bash
# Create static ARP entries for critical devices
arp -s 192.168.1.1 AA:BB:CC:DD:EE:FF  # Gateway
arp -s 192.168.1.2 11:22:33:44:55:66  # DNS server

# Verify
arp -a
```

#### Use DHCP Snooping
- Switch-level protection
- Validates DHCP messages
- Blocks rogue DHCP servers

#### Enable Port Security
```
Switch port security config:
- Maximum 1 MAC per port
- Shutdown on violation
- Dhcp snooping enabled
```

### 2. PQC Crypto Protection

Even if attacker achieves MITM position, your traffic is protected:

```
Traditional TLS (RSA):
  1. Attacker intercepts TLS handshake
  2. Attacker can later decrypt (with sufficient compute)
  
SIA_BANK with ML-KEM/ML-DSA:
  1. Attacker intercepts TLS handshake
  2. Attacker cannot decrypt even with quantum computer ✓
  3. Attacker cannot forge signatures (ML-DSA) ✓
```

### 3. Certificate Pinning

```java
// Pin expected certificate
public class PinningConfigurator {
    public static SSLContext createSSLContext() {
        // Pin to specific certificate
        String expectedHash = "sha256/AAAAAAA...";
        // Reject all other certificates
        return configureSSLContextWithPinning(expectedHash);
    }
}
```

### 4. HSTS (HTTP Strict Transport Security)

```
Add header: Strict-Transport-Security: max-age=31536000
Prevents downgrade from HTTPS to HTTP
Browser will refuse to connect via HTTP
```

### 5. Continuous Detection

```bash
# Run detector continuously
while true; do
    sudo python3 ebpf/detect_mitm_attacks.py \
        --interface eth0 \
        --output logs/mitm-attacks.jsonl
    sleep 3600  # Run hourly
done
```

### 6. Automatic Response

When MITM detected:
1. **Log**: Record attacker details
2. **Alert**: Send alert to security team
3. **Block**: Firewall blocks attacker IP/MAC
4. **Investigate**: Review attacker's actions
5. **Remediate**: Update ARP bindings, restart services

---

## Real-World Deployment

### Monitoring Infrastructure

```
Every microservice has:
  ├─ Local ARP cache (protected)
  ├─ Packet sniffer (tcpdump)
  └─ MITM detector (running continuously)
       ↓
All detection logs sent to SIEM
       ↓
Real-time alerting on MITM detection
```

### Integration with Services

```bash
# In start-services.sh, add MITM detection:
if [ "$EUID" -eq 0 ]; then
    sudo python3 ebpf/detect_mitm_attacks.py \
        --interface eth0 \
        --output logs/mitm-attacks.jsonl &
fi
```

### Alert Rules

```yaml
# prometheus/alert-rules.yml
alerts:
  - name: MITM_ATTACK_DETECTED
    condition: mitm_arp_spoofing_detected > 0
    severity: CRITICAL
    actions:
      - page_security_team
      - block_attacker_ip
      - enable_network_iso
```

### Compliance

This setup helps meet:
- **PCI-DSS**: Requirement 1.2.2 (network segmentation)
- **HIPAA**: Technical safeguards for data transmission
- **GDPR**: Security by design and default
- **SOC2**: Security monitoring and incident response

---

## Troubleshooting

### Detector Not Detecting Attacks

```bash
# Check if running with root
whoami  # Should be root

# Verify interface
ip link show

# Check if interface has traffic
sudo tcpdump -i eth0 -c 10

# Run detector with verbose
sudo python3 -u ebpf/detect_mitm_attacks.py \
    --interface eth0 2>&1 | tee debug.log
```

### ARP Spoofing Simulation Not Working

```bash
# Verify target is reachable
ping -c 1 192.168.1.105

# Check ARP table
arp -a

# Run with sudo and verbose
sudo python3 -u ebpf/simulate_mitm_attacks.py \
    --target 192.168.1.105 \
    --gateway 192.168.1.1 \
    --attack-type arp 2>&1 | tee attack.log
```

---

## Summary

This MITM detection system provides:

✓ **Detection**: Identifies ARP spoofing, DNS spoofing, packet sniffing  
✓ **Identification**: Pinpoints attacker IP, MAC, hostname, tool used  
✓ **Prevention**: Blocks identified attackers automatically  
✓ **Protection**: PQC crypto protects even if attacker achieves MITM  
✓ **Compliance**: Meets regulatory security requirements  

For questions, see [README.md](../README.md) or check detector output logs.
