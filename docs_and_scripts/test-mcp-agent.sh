#!/bin/bash
# Test MCP Security Agent Setup

echo "🧪 Testing MCP Security Agent Setup..."
echo ""

# Check if MCP agent file exists
if [ -f "mcp_security_agent.py" ]; then
    echo "✅ MCP agent file exists"
else
    echo "❌ MCP agent file not found"
    exit 1
fi

# Check if Python3 is available
if command -v python3 &> /dev/null; then
    echo "✅ Python3 available: $(python3 --version)"
else
    echo "❌ Python3 not found"
    exit 1
fi

# Check if MCP SDK is installed
if python3 -c "import mcp" 2>/dev/null; then
    echo "✅ MCP SDK installed"
else
    echo "❌ MCP SDK not installed (run: pip install mcp)"
    exit 1
fi

# Check if requests is installed
if python3 -c "import requests" 2>/dev/null; then
    echo "✅ Requests library installed"
else
    echo "❌ Requests library not installed (run: pip install requests)"
    exit 1
fi

# Check if log directories exist
if [ -d "logs" ]; then
    echo "✅ Logs directory exists"
else
    echo "⚠️  Logs directory not found (will be created automatically)"
fi

# Check for security log files
echo ""
echo "📋 Security Log Files:"
for log in logs/mitm-attacks.jsonl logs/ebpf-attack-demo.jsonl logs/security-actions.jsonl; do
    if [ -f "$log" ]; then
        events=$(wc -l < "$log")
        echo "   ✅ $log ($events events)"
    else
        echo "   ⚠️  $log (not found - will be created on first use)"
    fi
done

# Check Prometheus connectivity
echo ""
echo "🔍 Service Connectivity:"
if curl -s http://localhost:9090/-/healthy &>/dev/null; then
    echo "   ✅ Prometheus (localhost:9090)"
else
    echo "   ⚠️  Prometheus not reachable (localhost:9090)"
fi

if curl -s http://localhost:3000/api/health &>/dev/null; then
    echo "   ✅ Grafana (localhost:3000)"
else
    echo "   ⚠️  Grafana not reachable (localhost:3000)"
fi

echo ""
echo "📚 Agent Tools Available: 8"
echo "   • read_security_logs"
echo "   • analyze_threat"
echo "   • block_attacker_ip"
echo "   • query_prometheus_alerts"
echo "   • create_grafana_annotation"
echo "   • get_threat_summary"
echo "   • execute_response_action"
echo "   • watch_logs_realtime"

echo ""
echo "✅ MCP Security Agent is ready!"
echo ""
echo "Next steps:"
echo "1. Run: python3 mcp_security_agent.py (to start the agent)"
echo "2. Or configure Claude Desktop with this agent"
echo "3. Or run: sudo ./demo-mitm-attack.sh all 6 (to generate test events)"
echo ""
echo "For full setup guide, see: MCP_SECURITY_AGENT_SETUP.md"
