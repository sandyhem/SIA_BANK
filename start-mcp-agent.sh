#!/bin/bash
# MCP Security Agent Launcher
# Activates the correct virtual environment and runs the agent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if mcp-venv exists
if [ ! -d "mcp-venv" ]; then
    echo "❌ MCP virtual environment not found"
    echo "Creating it now..."
    python3 -m venv mcp-venv
    source mcp-venv/bin/activate
    pip install -q mcp requests
    echo "✅ Virtual environment created and dependencies installed"
else
    source mcp-venv/bin/activate
fi

# Run the MCP security agent
echo "🛡️  Starting MCP Security Agent..."
python3 mcp_security_agent.py "$@"
