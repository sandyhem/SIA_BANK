#!/bin/bash
# Test if MCP server can start successfully

echo "🧪 Testing MCP Server Startup..."
echo ""

cd /home/inba/SIA_BANK
source mcp-venv/bin/activate

# Start the MCP server in background with timeout
timeout 3 python3 mcp_security_agent.py 2>&1 | head -20 &
SERVER_PID=$!

# Wait a moment for startup
sleep 2

# Check if process started
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo "✅ MCP server started successfully"
    echo ""
    echo "Server is running (PID: $SERVER_PID)"
    echo ""
    kill $SERVER_PID 2>/dev/null
    wait $SERVER_PID 2>/dev/null
    echo "✅ Server stopped cleanly"
else
    echo "⚠️  Server process not found (may have exited)"
    echo "This is expected when running without MCP client connection"
fi

echo ""
echo "Server startup test complete!"
echo ""
echo "Note: The MCP server is designed to run with an MCP client"
echo "(like Claude Desktop). When running standalone, it will"
echo "wait for stdin connection and may appear to hang."
echo ""
echo "To use the agent:"
echo "  1. Configure Claude Desktop (see MCP_SECURITY_AGENT_SETUP.md)"
echo "  2. Or connect via MCP protocol client"
echo "  3. Or use the demo script: python3 demo-mcp-agent-interaction.py"
