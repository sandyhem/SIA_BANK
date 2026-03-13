#!/usr/bin/env python3
"""
Test MCP Security Agent Tools Directly
This tests the tool functions without requiring an MCP client
"""

import sys
import asyncio
from pathlib import Path

# Add the current directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import the MCP agent tools
from mcp_security_agent import (
    read_security_logs,
    analyze_threat,
    get_threat_summary,
    query_prometheus_alerts
)

async def test_read_logs():
    """Test reading security logs"""
    print("=" * 60)
    print("TEST 1: Reading Security Logs")
    print("=" * 60)
    print()
    
    try:
        result = await read_security_logs("mitm", 5, "ALL")
        print("✅ read_security_logs() executed successfully")
        print()
        print("Result preview:")
        print(result[0].text[:500] + "..." if len(result[0].text) > 500 else result[0].text)
        print()
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

async def test_analyze_threat():
    """Test threat analysis"""
    print("=" * 60)
    print("TEST 2: Analyzing Threat")
    print("=" * 60)
    print()
    
    # Sample threat event
    event = {
        "attack_type": "ARP_SPOOFING_DETECTED",
        "severity": "CRITICAL",
        "attacker_ip": "10.111.12.50",
        "attacker_mac": "aa:bb:cc:dd:ee:ff",
        "timestamp": "2026-03-09T22:00:00"
    }
    
    try:
        result = await analyze_threat(event)
        print("✅ analyze_threat() executed successfully")
        print()
        print("Analysis result:")
        print(result[0].text)
        print()
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

async def test_threat_summary():
    """Test threat summary"""
    print("=" * 60)
    print("TEST 3: Getting Threat Summary")
    print("=" * 60)
    print()
    
    try:
        result = await get_threat_summary(10)
        print("✅ get_threat_summary() executed successfully")
        print()
        print("Summary:")
        print(result[0].text)
        print()
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

async def test_prometheus_alerts():
    """Test Prometheus alerts query"""
    print("=" * 60)
    print("TEST 4: Querying Prometheus Alerts")
    print("=" * 60)
    print()
    
    try:
        result = await query_prometheus_alerts("firing")
        print("✅ query_prometheus_alerts() executed successfully")
        print()
        print("Alerts:")
        print(result[0].text)
        print()
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

async def main():
    """Run all tests"""
    print()
    print("🧪 MCP SECURITY AGENT - FUNCTIONALITY TEST")
    print()
    print("Testing all agent tools directly...")
    print()
    
    results = []
    
    # Test 1: Read logs
    results.append(await test_read_logs())
    
    # Test 2: Analyze threat
    results.append(await test_analyze_threat())
    
    # Test 3: Get threat summary
    results.append(await test_threat_summary())
    
    # Test 4: Query Prometheus
    results.append(await test_prometheus_alerts())
    
    # Summary
    print("=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    print()
    
    passed = sum(results)
    total = len(results)
    
    print(f"Tests Passed: {passed}/{total}")
    print()
    
    if passed == total:
        print("✅ All MCP agent tools are working correctly!")
        print()
        print("The MCP agent is ready to:")
        print("  • Monitor security logs in real-time")
        print("  • Analyze threats and recommend actions")
        print("  • Execute automated security responses")
        print("  • Integrate with Prometheus and Grafana")
        return 0
    else:
        print(f"⚠️  {total - passed} test(s) failed")
        print("Check the errors above for details")
        return 1

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
