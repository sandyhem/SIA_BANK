#!/usr/bin/env python3
"""
Demo script showing how the MCP Security Agent responds to threats
This simulates what Claude Desktop would do when interacting with the agent
"""

import json
from pathlib import Path

# Paths
BASE_DIR = Path("/home/inba/SIA_BANK")
LOGS_DIR = BASE_DIR / "logs"
MITM_LOG = LOGS_DIR / "mitm-attacks.jsonl"
EBPF_LOG = LOGS_DIR / "ebpf-attack-demo.jsonl"

def demo_read_logs():
    """Demo: Read recent security events"""
    print("=" * 60)
    print("DEMO 1: Reading Recent Security Events")
    print("=" * 60)
    print()
    
    print("User: Show me CRITICAL security events from MITM logs")
    print()
    
    if not MITM_LOG.exists():
        print("⚠️  No MITM log found. Run: sudo ./demo-mitm-attack.sh all 6")
        return
    
    # Simulate reading logs
    events = []
    with open(MITM_LOG, "r") as f:
        for line in f:
            try:
                event = json.loads(line.strip())
                if event.get("severity") == "CRITICAL":
                    events.append(event)
            except:
                continue
    
    print(f"Agent: Found {len(events)} CRITICAL events:")
    print()
    for i, event in enumerate(events, 1):
        print(f"Event {i}:")
        print(f"  • Type: {event.get('attack_type')}")
        print(f"  • Severity: {event.get('severity')}")
        print(f"  • Attacker IP: {event.get('attacker_ip')}")
        print(f"  • Attacker MAC: {event.get('attacker_mac')}")
        print(f"  • Time: {event.get('timestamp')}")
        print()

def demo_threat_analysis():
    """Demo: Analyze a threat"""
    print("=" * 60)
    print("DEMO 2: Threat Analysis")
    print("=" * 60)
    print()
    
    # Sample threat event
    event = {
        "attack_type": "ARP_SPOOFING_DETECTED",
        "severity": "CRITICAL",
        "attacker_ip": "10.111.12.50",
        "attacker_mac": "aa:bb:cc:dd:ee:ff"
    }
    
    print("User: Analyze this threat:")
    print(json.dumps(event, indent=2))
    print()
    
    print("Agent: Threat Analysis:")
    print()
    print("  Risk Score: 95/100")
    print("  Confidence: HIGH")
    print("  Urgency: IMMEDIATE")
    print()
    print("  Recommended Actions:")
    print("    1. BLOCK_IP - Block attacker IP immediately")
    print("    2. ALERT_TEAM - Notify security team")
    print("    3. ISOLATE_NETWORK - Isolate affected network segment")
    print("    4. FORENSICS - Capture network traffic for analysis")
    print()

def demo_automated_response():
    """Demo: Automated response execution"""
    print("=" * 60)
    print("DEMO 3: Automated Response (Simulation)")
    print("=" * 60)
    print()
    
    print("User: Block attacker IP 10.111.12.50 due to ARP spoofing")
    print()
    
    print("Agent: Executing security response...")
    print()
    print("  ✅ Checked if IP already blocked")
    print("  ✅ Added iptables DROP rule for 10.111.12.50")
    print("  ✅ Logged action to security-actions.jsonl")
    print("  ✅ Created Grafana annotation")
    print()
    print("  Result:")
    print("    {")
    print('      "status": "blocked",')
    print('      "ip": "10.111.12.50",')
    print('      "reason": "ARP_SPOOFING_DETECTED - CRITICAL",')
    print('      "message": "Successfully blocked IP 10.111.12.50"')
    print("    }")
    print()
    print("  ⚠️  NOTE: This is a simulation. Real blocking requires sudo access.")
    print()

def demo_threat_summary():
    """Demo: Get threat summary"""
    print("=" * 60)
    print("DEMO 4: Threat Summary")
    print("=" * 60)
    print()
    
    print("User: Give me a threat summary for the last 10 minutes")
    print()
    
    # Count events in logs
    mitm_count = 0
    ebpf_count = 0
    severity_breakdown = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}
    
    if MITM_LOG.exists():
        with open(MITM_LOG, "r") as f:
            for line in f:
                try:
                    event = json.loads(line.strip())
                    mitm_count += 1
                    severity = event.get("severity", "LOW")
                    severity_breakdown[severity] = severity_breakdown.get(severity, 0) + 1
                except:
                    continue
    
    if EBPF_LOG.exists():
        with open(EBPF_LOG, "r") as f:
            for line in f:
                try:
                    event = json.loads(line.strip())
                    ebpf_count += 1
                    severity = event.get("severity", "LOW")
                    severity_breakdown[severity] = severity_breakdown.get(severity, 0) + 1
                except:
                    continue
    
    total = mitm_count + ebpf_count
    
    print("Agent: Threat Summary (All Time):")
    print()
    print(f"  Total Threats: {total}")
    print(f"  MITM Attacks: {mitm_count}")
    print(f"  eBPF Events: {ebpf_count}")
    print()
    print("  Severity Breakdown:")
    print(f"    • CRITICAL: {severity_breakdown['CRITICAL']}")
    print(f"    • HIGH: {severity_breakdown['HIGH']}")
    print(f"    • MEDIUM: {severity_breakdown['MEDIUM']}")
    print(f"    • LOW: {severity_breakdown['LOW']}")
    print()

def demo_prometheus_alerts():
    """Demo: Query Prometheus"""
    print("=" * 60)
    print("DEMO 5: Prometheus Alerts")
    print("=" * 60)
    print()
    
    print("User: Show me firing Prometheus alerts")
    print()
    print("Agent: Querying Prometheus at http://localhost:9090...")
    print()
    
    import requests
    try:
        response = requests.get("http://localhost:9090/api/v1/alerts", timeout=5)
        if response.status_code == 200:
            data = response.json()
            alerts = data.get("data", {}).get("alerts", [])
            firing = [a for a in alerts if a.get("state") == "firing"]
            
            if firing:
                print(f"  Found {len(firing)} firing alerts:")
                for alert in firing[:3]:  # Show first 3
                    print(f"    • {alert.get('labels', {}).get('alertname')}")
                    print(f"      Severity: {alert.get('labels', {}).get('severity')}")
                    print(f"      Status: {alert.get('state')}")
                print()
            else:
                print("  ✅ No firing alerts")
        else:
            print("  ⚠️  Prometheus returned error")
    except:
        print("  ⚠️  Could not connect to Prometheus")
        print("     Make sure it's running on http://localhost:9090")
    print()

def main():
    """Run all demos"""
    print()
    print("🛡️  MCP SECURITY AGENT - INTERACTION DEMO")
    print()
    print("This demonstrates how Claude Desktop (or any MCP client)")
    print("would interact with the security agent to monitor and")
    print("respond to threats.")
    print()
    
    demo_read_logs()
    input("Press Enter to continue to next demo...")
    print()
    
    demo_threat_analysis()
    input("Press Enter to continue to next demo...")
    print()
    
    demo_automated_response()
    input("Press Enter to continue to next demo...")
    print()
    
    demo_threat_summary()
    input("Press Enter to continue to next demo...")
    print()
    
    demo_prometheus_alerts()
    
    print("=" * 60)
    print("DEMO COMPLETE")
    print("=" * 60)
    print()
    print("To actually run the MCP agent:")
    print("  ./start-mcp-agent.sh")
    print()
    print("To configure with Claude Desktop:")
    print("  See MCP_SECURITY_AGENT_SETUP.md")
    print()

if __name__ == "__main__":
    main()
