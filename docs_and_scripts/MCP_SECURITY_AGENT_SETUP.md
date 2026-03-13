# MCP Security Agent Setup Guide

## Overview
The MCP Security Agent is an autonomous security monitoring system that watches your eBPF and MITM detection logs, analyzes threats in real-time, and takes automated defensive actions.

## Installation

### 1. Everything is Pre-configured!
The MCP agent comes with a launcher script that automatically:
- Creates a virtual environment (mcp-venv) if needed
- Installs required dependencies (mcp, requests)
- Activates the environment and starts the agent

**Quick Start:**
```bash
./start-mcp-agent.sh
```

### 2. Manual Installation (Optional)
If you prefer to install manually:
```bash
python3 -m venv mcp-venv
source mcp-venv/bin/activate
pip install mcp requests
```

### 3. Configure Grafana API Key (Optional)
Edit `mcp_security_agent.py` line 34 to set your Grafana API key:
```python
GRAFANA_API_KEY = "your-api-key-here"  # Or keep "admin:admin" for basic auth
```

## Running the Agent

### Standalone Mode (Recommended)
Use the launcher script that handles all environment setup:
```bash
./start-mcp-agent.sh
```

### Manual Mode (Advanced)
```bash
source mcp-venv/bin/activate
python3 mcp_security_agent.py
```

### With MCP Client (Claude Desktop)
Add to your Claude Desktop config:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "security-agent": {
      "command": "/home/inba/SIA_BANK/start-mcp-agent.sh"
    }
  }
}
```

Then restart Claude Desktop.

## Available Tools

### 1. **read_security_logs**
Read recent security events from logs.

**Parameters:**
- `log_type`: "mitm", "ebpf", or "actions"
- `lines`: Number of recent lines to read (default: 10)
- `severity_filter`: "CRITICAL", "HIGH", "MEDIUM", "LOW", or "ALL"

**Example:**
```
Read the last 20 CRITICAL security events from MITM logs
```

### 2. **analyze_threat**
Analyze a security event and get recommended actions.

**Parameters:**
- `event`: JSON security event object

**Example:**
```
Analyze this threat: {"attack_type": "ARP_SPOOFING_DETECTED", "severity": "CRITICAL", "attacker_ip": "10.111.12.50"}
```

### 3. **block_attacker_ip**
Block an attacker IP using iptables (requires sudo).

**Parameters:**
- `ip`: IP address to block
- `reason`: Reason for blocking
- `duration`: "temporary" or "permanent"

**Example:**
```
Block IP 10.111.12.50 because of ARP spoofing attack
```

### 4. **query_prometheus_alerts**
Get current alerts from Prometheus.

**Parameters:**
- `state_filter`: "firing", "pending", "inactive", or "all"

**Example:**
```
Show me all firing alerts from Prometheus
```

### 5. **create_grafana_annotation**
Create an annotation in Grafana to mark security events.

**Parameters:**
- `text`: Annotation text
- `tags`: Array of tags (default: ["security"])

**Example:**
```
Create a Grafana annotation: "MITM attack blocked from 10.111.12.50"
```

### 6. **get_threat_summary**
Get summary of all threats in a time window.

**Parameters:**
- `minutes`: Time window in minutes (default: 10)

**Example:**
```
Show me a threat summary for the last 30 minutes
```

### 7. **execute_response_action**
Execute or recommend automated security responses.

**Parameters:**
- `threat_type`: Type of threat (e.g., "ARP_SPOOFING_DETECTED")
- `severity`: "CRITICAL", "HIGH", "MEDIUM", "LOW"
- `attacker_ip`: Attacker IP address (optional)
- `action_mode`: "auto" (execute) or "recommend" (suggest only)

**Example:**
```
Execute automatic response for critical ARP spoofing from 10.111.12.50
```

### 8. **watch_logs_realtime**
Start real-time log monitoring.

**Parameters:**
- `duration`: Watch duration in seconds (default: 60)

**Example:**
```
Watch security logs in real-time for 120 seconds
```

## Usage Workflows

### Workflow 1: Manual Threat Investigation
1. **Check recent threats**: "Show me CRITICAL events from the last 10 minutes"
2. **Analyze specific threat**: "Analyze this ARP spoofing event"
3. **Take action**: "Block the attacker IP 10.111.12.50"
4. **Document**: "Create a Grafana annotation about this incident"

### Workflow 2: Automated Monitoring
1. **Get threat summary**: "Summarize all threats in the last hour"
2. **Check Prometheus alerts**: "Show firing Prometheus alerts"
3. **Auto-respond**: "Execute automatic response for critical threats"

### Workflow 3: Real-time Monitoring
```
Watch security logs for 5 minutes and alert me on any CRITICAL events
```

## Example Conversation with Agent

**User:** "What security threats have we seen in the last 10 minutes?"

**Agent:** *Uses read_security_logs and get_threat_summary*

**User:** "Analyze the ARP spoofing attack"

**Agent:** *Uses analyze_threat, provides risk score and recommendations*

**User:** "Block that attacker IP immediately"

**Agent:** *Uses block_attacker_ip, creates Grafana annotation*

## Automated Response Logic

### Critical Threats (Auto-block)
- **ARP_SPOOFING_DETECTED** + CRITICAL → Block IP immediately
- **LATERAL_MOVEMENT** + HIGH/CRITICAL → Alert team, audit connections

### Medium Threats (Monitor)
- **PROCESS_PORT_MISMATCH** → Investigate, increase monitoring
- **UNUSUAL_TRAFFIC** → Log and monitor

### Low Threats (Log Only)
- Generic anomalies → Document for review

## Security Actions Log

All agent actions are logged to `logs/security-actions.jsonl`:
```json
{
  "timestamp": "2026-03-09T22:15:30.123456",
  "action": "BLOCK_IP",
  "details": {
    "ip": "10.111.12.50",
    "reason": "ARP_SPOOFING_DETECTED - CRITICAL",
    "status": "blocked"
  },
  "agent": "mcp_security_agent"
}
```

## Troubleshooting

### MCP SDK Not Found
```bash
pip install mcp
```

### Prometheus/Grafana Connection Errors
- Ensure services are running: `docker-compose ps` (if using Docker)
- Check URLs in `mcp_security_agent.py` (lines 29-31)
- Verify network connectivity: `curl http://localhost:9090/api/v1/alerts`

### iptables Permission Denied
- Agent requires sudo for blocking IPs
- Add to sudoers (advanced): `echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/iptables" | sudo tee /etc/sudoers.d/mcp-agent`

### No Security Events
- Run attack simulation: `sudo ./demo-mitm-attack.sh all 6`
- Verify logs exist: `ls -lh logs/*.jsonl`
- Check log permissions: `chmod 644 logs/*.jsonl`

## Integration with Existing Tools

### With Prometheus Alertmanager
Configure Alertmanager to webhook the MCP agent when critical alerts fire.

### With Grafana Dashboards
The agent automatically creates annotations visible on all dashboards.

### With eBPF Monitoring
The agent reads `logs/ebpf-attack-demo.jsonl` for eBPF events from your monitoring stack.

## Advanced: Continuous Monitoring Script

Create `monitor-with-mcp.sh`:
```bash
#!/bin/bash
# Continuous security monitoring with MCP agent

while true; do
    echo "Checking for threats..."
    # MCP client command here (depends on your MCP client setup)
    sleep 60
done
```

## Next Steps

1. **Test the setup**: `./test-mcp-agent.sh`
2. **Run the agent**: `./start-mcp-agent.sh`
3. **Generate test events**: `sudo ./demo-mitm-attack.sh all 6`
4. **Interact with agent**: See usage examples below or configure Claude Desktop

## Support

For issues or questions:
- Check logs: `tail -f logs/security-actions.jsonl`
- Review detection logs: `cat logs/mitm-attacks.jsonl`
- Verify Prometheus: `curl http://localhost:9090/api/v1/alerts`
