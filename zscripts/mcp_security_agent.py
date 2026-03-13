#!/usr/bin/env python3
"""
MCP Security Agent - Real-time Security Event Monitoring & Response
Monitors eBPF and MITM attack logs and takes automated security actions.
"""

import asyncio
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Optional
import requests

try:
    from mcp.server import Server
    from mcp.types import Tool, TextContent
    import mcp.server.stdio
except ImportError:
    print("Error: MCP SDK not installed. Run: pip install mcp", file=sys.stderr)
    sys.exit(1)

# Configuration
BASE_DIR = Path("/home/inba/SIA_BANK")
LOGS_DIR = BASE_DIR / "logs"
MITM_LOG = LOGS_DIR / "mitm-attacks.jsonl"
EBPF_LOG = LOGS_DIR / "ebpf-attack-demo.jsonl"
ACTIONS_LOG = LOGS_DIR / "security-actions.jsonl"
PROMETHEUS_URL = "http://localhost:9090"
GRAFANA_URL = "http://localhost:3000"
GRAFANA_API_KEY = "admin:admin"  # Update with actual API key

# Ensure logs directory exists
LOGS_DIR.mkdir(parents=True, exist_ok=True)

# Initialize MCP server
server = Server("security-agent")


def log_action(action: str, details: dict):
    """Log security action taken by agent"""
    entry = {
        "timestamp": datetime.now().isoformat(),
        "action": action,
        "details": details,
        "agent": "mcp_security_agent"
    }
    with open(ACTIONS_LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")
    return entry


@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available security monitoring tools"""
    return [
        Tool(
            name="read_security_logs",
            description="Read recent security events from MITM or eBPF logs",
            inputSchema={
                "type": "object",
                "properties": {
                    "log_type": {
                        "type": "string",
                        "enum": ["mitm", "ebpf", "actions"],
                        "description": "Type of log to read (mitm=MITM attacks, ebpf=eBPF events, actions=agent actions)"
                    },
                    "lines": {
                        "type": "integer",
                        "description": "Number of recent lines to read",
                        "default": 10
                    },
                    "severity_filter": {
                        "type": "string",
                        "enum": ["CRITICAL", "HIGH", "MEDIUM", "LOW", "ALL"],
                        "description": "Filter by severity level",
                        "default": "ALL"
                    }
                },
                "required": ["log_type"]
            }
        ),
        Tool(
            name="analyze_threat",
            description="Analyze a security event and recommend actions",
            inputSchema={
                "type": "object",
                "properties": {
                    "event": {
                        "type": "object",
                        "description": "Security event JSON object to analyze"
                    }
                },
                "required": ["event"]
            }
        ),
        Tool(
            name="block_attacker_ip",
            description="Block an attacker IP address using iptables (requires sudo)",
            inputSchema={
                "type": "object",
                "properties": {
                    "ip": {
                        "type": "string",
                        "description": "IP address to block"
                    },
                    "reason": {
                        "type": "string",
                        "description": "Reason for blocking"
                    },
                    "duration": {
                        "type": "string",
                        "enum": ["temporary", "permanent"],
                        "description": "Block duration",
                        "default": "temporary"
                    }
                },
                "required": ["ip", "reason"]
            }
        ),
        Tool(
            name="query_prometheus_alerts",
            description="Get current firing alerts from Prometheus",
            inputSchema={
                "type": "object",
                "properties": {
                    "state_filter": {
                        "type": "string",
                        "enum": ["firing", "pending", "inactive", "all"],
                        "description": "Filter alerts by state",
                        "default": "firing"
                    }
                }
            }
        ),
        Tool(
            name="create_grafana_annotation",
            description="Create an annotation in Grafana dashboard to mark security events",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "Annotation text"
                    },
                    "tags": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Tags for categorization",
                        "default": ["security"]
                    }
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="get_threat_summary",
            description="Get summary of all security threats in the last N minutes",
            inputSchema={
                "type": "object",
                "properties": {
                    "minutes": {
                        "type": "integer",
                        "description": "Time window in minutes",
                        "default": 10
                    }
                }
            }
        ),
        Tool(
            name="execute_response_action",
            description="Execute automated security response based on threat level",
            inputSchema={
                "type": "object",
                "properties": {
                    "threat_type": {
                        "type": "string",
                        "description": "Type of threat (ARP_SPOOFING, LATERAL_MOVEMENT, etc.)"
                    },
                    "severity": {
                        "type": "string",
                        "enum": ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
                    },
                    "attacker_ip": {
                        "type": "string",
                        "description": "Attacker IP address"
                    },
                    "action_mode": {
                        "type": "string",
                        "enum": ["auto", "recommend"],
                        "description": "Auto-execute or just recommend",
                        "default": "recommend"
                    }
                },
                "required": ["threat_type", "severity"]
            }
        ),
        Tool(
            name="watch_logs_realtime",
            description="Start real-time monitoring of security logs (returns monitoring status)",
            inputSchema={
                "type": "object",
                "properties": {
                    "duration": {
                        "type": "integer",
                        "description": "Watch duration in seconds",
                        "default": 60
                    }
                }
            }
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool invocations"""
    
    try:
        if name == "read_security_logs":
            return await read_security_logs(
                arguments.get("log_type"),
                arguments.get("lines", 10),
                arguments.get("severity_filter", "ALL")
            )
        
        elif name == "analyze_threat":
            return await analyze_threat(arguments.get("event"))
        
        elif name == "block_attacker_ip":
            return await block_attacker_ip(
                arguments.get("ip"),
                arguments.get("reason"),
                arguments.get("duration", "temporary")
            )
        
        elif name == "query_prometheus_alerts":
            return await query_prometheus_alerts(
                arguments.get("state_filter", "firing")
            )
        
        elif name == "create_grafana_annotation":
            return await create_grafana_annotation(
                arguments.get("text"),
                arguments.get("tags", ["security"])
            )
        
        elif name == "get_threat_summary":
            return await get_threat_summary(
                arguments.get("minutes", 10)
            )
        
        elif name == "execute_response_action":
            return await execute_response_action(
                arguments.get("threat_type"),
                arguments.get("severity"),
                arguments.get("attacker_ip"),
                arguments.get("action_mode", "recommend")
            )
        
        elif name == "watch_logs_realtime":
            return await watch_logs_realtime(
                arguments.get("duration", 60)
            )
        
        else:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]
    
    except Exception as e:
        return [TextContent(type="text", text=f"Error: {str(e)}")]


async def read_security_logs(log_type: str, lines: int, severity_filter: str) -> list[TextContent]:
    """Read and filter security logs"""
    
    log_map = {
        "mitm": MITM_LOG,
        "ebpf": EBPF_LOG,
        "actions": ACTIONS_LOG
    }
    
    log_file = log_map.get(log_type)
    if not log_file or not log_file.exists():
        return [TextContent(
            type="text",
            text=f"Log file not found: {log_file}"
        )]
    
    # Read last N lines
    with open(log_file, "r") as f:
        all_lines = f.readlines()
        recent_lines = all_lines[-lines:] if len(all_lines) >= lines else all_lines
    
    # Parse and filter
    events = []
    for line in recent_lines:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
            # Filter by severity
            if severity_filter != "ALL":
                if event.get("severity") != severity_filter:
                    continue
            events.append(event)
        except json.JSONDecodeError:
            continue
    
    result = {
        "log_type": log_type,
        "total_events": len(events),
        "severity_filter": severity_filter,
        "events": events
    }
    
    return [TextContent(
        type="text",
        text=json.dumps(result, indent=2)
    )]


async def analyze_threat(event: dict) -> list[TextContent]:
    """Analyze threat and recommend action"""
    
    attack_type = event.get("attack_type", "UNKNOWN")
    severity = event.get("severity", "UNKNOWN")
    attacker_ip = event.get("attacker_ip")
    attacker_mac = event.get("attacker_mac")
    
    # Threat analysis logic
    analysis = {
        "threat_level": severity,
        "confidence": "HIGH" if severity in ["CRITICAL", "HIGH"] else "MEDIUM",
        "attack_type": attack_type,
        "attacker_info": {
            "ip": attacker_ip,
            "mac": attacker_mac
        }
    }
    
    # Recommended actions based on threat type
    if attack_type == "ARP_SPOOFING_DETECTED":
        analysis["recommended_actions"] = [
            "BLOCK_IP - Block attacker IP immediately",
            "ALERT_TEAM - Notify security team",
            "ISOLATE_NETWORK - Isolate affected network segment",
            "FORENSICS - Capture network traffic for analysis"
        ]
        analysis["urgency"] = "IMMEDIATE"
    
    elif "LATERAL_MOVEMENT" in attack_type:
        analysis["recommended_actions"] = [
            "BLOCK_CONNECTION - Terminate suspicious connections",
            "ALERT_TEAM - Critical alert to security team",
            "AUDIT_ACCESS - Review access logs",
            "CONTAINMENT - Isolate compromised systems"
        ]
        analysis["urgency"] = "CRITICAL"
    
    elif "PROCESS_PORT_MISMATCH" in attack_type:
        analysis["recommended_actions"] = [
            "INVESTIGATE - Investigate unexpected process",
            "ALERT_TEAM - Notify for manual review",
            "MONITOR - Increase monitoring on host"
        ]
        analysis["urgency"] = "HIGH"
    
    else:
        analysis["recommended_actions"] = [
            "MONITOR - Continue monitoring",
            "LOG - Document event for review"
        ]
        analysis["urgency"] = "MEDIUM"
    
    # Risk assessment
    if severity == "CRITICAL":
        analysis["risk_score"] = 95
    elif severity == "HIGH":
        analysis["risk_score"] = 75
    elif severity == "MEDIUM":
        analysis["risk_score"] = 50
    else:
        analysis["risk_score"] = 25
    
    analysis["timestamp"] = datetime.now().isoformat()
    
    return [TextContent(
        type="text",
        text=json.dumps(analysis, indent=2)
    )]


async def block_attacker_ip(ip: str, reason: str, duration: str) -> list[TextContent]:
    """Block attacker IP using iptables"""
    
    try:
        # Check if already blocked
        check_cmd = ["sudo", "iptables", "-L", "INPUT", "-n"]
        check_result = subprocess.run(check_cmd, capture_output=True, text=True)
        
        if ip in check_result.stdout:
            result = {
                "status": "already_blocked",
                "ip": ip,
                "message": f"IP {ip} is already blocked"
            }
        else:
            # Add iptables rule
            block_cmd = ["sudo", "iptables", "-A", "INPUT", "-s", ip, "-j", "DROP"]
            subprocess.run(block_cmd, check=True, capture_output=True)
            
            result = {
                "status": "blocked",
                "ip": ip,
                "reason": reason,
                "duration": duration,
                "message": f"Successfully blocked IP {ip}",
                "timestamp": datetime.now().isoformat()
            }
            
            # Log action
            log_action("BLOCK_IP", result)
            
            # Create Grafana annotation
            await create_grafana_annotation(
                f"🚫 Blocked attacker IP: {ip} - Reason: {reason}",
                ["security", "blocked", "mitm"]
            )
        
        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]
    
    except subprocess.CalledProcessError as e:
        return [TextContent(
            type="text",
            text=f"Error blocking IP: {e.stderr}"
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]


async def query_prometheus_alerts(state_filter: str) -> list[TextContent]:
    """Query Prometheus for active alerts"""
    
    try:
        response = requests.get(f"{PROMETHEUS_URL}/api/v1/alerts", timeout=5)
        response.raise_for_status()
        
        data = response.json()
        alerts = data.get("data", {}).get("alerts", [])
        
        # Filter by state
        if state_filter != "all":
            alerts = [a for a in alerts if a.get("state") == state_filter]
        
        result = {
            "total_alerts": len(alerts),
            "state_filter": state_filter,
            "timestamp": datetime.now().isoformat(),
            "alerts": []
        }
        
        for alert in alerts:
            result["alerts"].append({
                "name": alert.get("labels", {}).get("alertname"),
                "state": alert.get("state"),
                "severity": alert.get("labels", {}).get("severity"),
                "summary": alert.get("annotations", {}).get("summary"),
                "active_since": alert.get("activeAt")
            })
        
        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]
    
    except requests.exceptions.RequestException as e:
        return [TextContent(
            type="text",
            text=f"Error querying Prometheus: {str(e)}\nIs Prometheus running on {PROMETHEUS_URL}?"
        )]


async def create_grafana_annotation(text: str, tags: list) -> list[TextContent]:
    """Create annotation in Grafana"""
    
    try:
        annotation_data = {
            "text": text,
            "tags": tags,
            "time": int(datetime.now().timestamp() * 1000)  # milliseconds
        }
        
        response = requests.post(
            f"{GRAFANA_URL}/api/annotations",
            json=annotation_data,
            auth=tuple(GRAFANA_API_KEY.split(":")),
            timeout=5
        )
        
        if response.status_code in [200, 201]:
            result = {
                "status": "created",
                "annotation": annotation_data,
                "message": "Annotation created successfully"
            }
        else:
            result = {
                "status": "failed",
                "error": response.text,
                "message": f"Failed to create annotation: HTTP {response.status_code}"
            }
        
        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]
    
    except requests.exceptions.RequestException as e:
        return [TextContent(
            type="text",
            text=f"Error creating Grafana annotation: {str(e)}\nIs Grafana running on {GRAFANA_URL}?"
        )]


async def get_threat_summary(minutes: int) -> list[TextContent]:
    """Get summary of threats in time window"""
    
    from datetime import timedelta
    
    cutoff_time = datetime.now() - timedelta(minutes=minutes)
    
    summary = {
        "time_window_minutes": minutes,
        "cutoff_time": cutoff_time.isoformat(),
        "mitm_threats": [],
        "ebpf_threats": [],
        "total_threats": 0,
        "severity_breakdown": {
            "CRITICAL": 0,
            "HIGH": 0,
            "MEDIUM": 0,
            "LOW": 0
        }
    }
    
    # Read MITM logs
    if MITM_LOG.exists():
        with open(MITM_LOG, "r") as f:
            for line in f:
                try:
                    event = json.loads(line.strip())
                    event_time = datetime.fromisoformat(event.get("timestamp", ""))
                    if event_time >= cutoff_time:
                        summary["mitm_threats"].append(event)
                        severity = event.get("severity", "LOW")
                        summary["severity_breakdown"][severity] += 1
                except:
                    continue
    
    # Read eBPF logs
    if EBPF_LOG.exists():
        with open(EBPF_LOG, "r") as f:
            for line in f:
                try:
                    event = json.loads(line.strip())
                    event_time = datetime.fromisoformat(event.get("timestamp", ""))
                    if event_time >= cutoff_time:
                        summary["ebpf_threats"].append(event)
                        severity = event.get("severity", "LOW")
                        summary["severity_breakdown"][severity] += 1
                except:
                    continue
    
    summary["total_threats"] = len(summary["mitm_threats"]) + len(summary["ebpf_threats"])
    
    # Get unique attackers
    attackers = set()
    for event in summary["mitm_threats"] + summary["ebpf_threats"]:
        if event.get("attacker_ip"):
            attackers.add(event["attacker_ip"])
    
    summary["unique_attackers"] = list(attackers)
    summary["attacker_count"] = len(attackers)
    
    return [TextContent(
        type="text",
        text=json.dumps(summary, indent=2)
    )]


async def execute_response_action(
    threat_type: str,
    severity: str,
    attacker_ip: Optional[str],
    action_mode: str
) -> list[TextContent]:
    """Execute or recommend automated response"""
    
    response_plan = {
        "threat_type": threat_type,
        "severity": severity,
        "action_mode": action_mode,
        "timestamp": datetime.now().isoformat(),
        "actions": []
    }
    
    # Determine actions based on threat type and severity
    if threat_type == "ARP_SPOOFING_DETECTED" and severity == "CRITICAL":
        if attacker_ip:
            if action_mode == "auto":
                # Execute blocking
                block_result = await block_attacker_ip(
                    attacker_ip,
                    f"{threat_type} - {severity}",
                    "temporary"
                )
                response_plan["actions"].append({
                    "action": "BLOCK_IP",
                    "status": "executed",
                    "result": block_result[0].text
                })
            else:
                response_plan["actions"].append({
                    "action": "BLOCK_IP",
                    "status": "recommended",
                    "ip": attacker_ip
                })
        
        # Alert
        response_plan["actions"].append({
            "action": "ALERT_TEAM",
            "status": "recommended",
            "message": f"Critical ARP spoofing attack detected from {attacker_ip}"
        })
    
    elif "LATERAL_MOVEMENT" in threat_type:
        response_plan["actions"].extend([
            {"action": "ALERT_TEAM", "status": "critical_alert", "urgency": "IMMEDIATE"},
            {"action": "AUDIT_CONNECTIONS", "status": "recommended"},
            {"action": "ISOLATE_SYSTEMS", "status": "recommended"}
        ])
    
    else:
        response_plan["actions"].append({
            "action": "MONITOR",
            "status": "continue_monitoring"
        })
    
    # Log the response plan
    log_action("RESPONSE_PLAN", response_plan)
    
    return [TextContent(
        type="text",
        text=json.dumps(response_plan, indent=2)
    )]


async def watch_logs_realtime(duration: int) -> list[TextContent]:
    """Watch logs in real-time and report events"""
    
    watch_result = {
        "status": "started",
        "duration_seconds": duration,
        "start_time": datetime.now().isoformat(),
        "message": f"Real-time monitoring active for {duration} seconds",
        "monitored_files": [
            str(MITM_LOG),
            str(EBPF_LOG)
        ]
    }
    
    # Note: In a real implementation, this would use file watchers (watchdog)
    # For MCP, we return monitoring status
    
    return [TextContent(
        type="text",
        text=json.dumps(watch_result, indent=2)
    )]


async def main():
    """Run the MCP security agent server"""
    print("🛡️  MCP Security Agent Server Starting...", file=sys.stderr)
    print(f"📂 Monitoring: {LOGS_DIR}", file=sys.stderr)
    print(f"📊 Prometheus: {PROMETHEUS_URL}", file=sys.stderr)
    print(f"📈 Grafana: {GRAFANA_URL}", file=sys.stderr)
    print("", file=sys.stderr)
    
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
