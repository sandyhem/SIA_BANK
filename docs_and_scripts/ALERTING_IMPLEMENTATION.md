# eBPF Alerting System - Implementation Summary

## Overview

Automated alerting has been added to the eBPF security monitoring stack. The system now automatically detects and alerts on critical security events through Prometheus alert rules and Grafana visualization.

## What Was Implemented

### 1. Prometheus Alert Rules (`observability/prometheus/alert-rules.yml`)

Seven alert rules covering different security scenarios:

| Alert | Severity | Condition | For Duration | Purpose |
|-------|----------|-----------|--------------|---------|
| **LateralMovementDetected** | 🔴 Critical | Any lateral movement detected | 15s | Immediate notification of potential network pivoting |
| **ProcessPortMismatchHigh** | 🟠 High | >0.5 mismatches/sec | 30s | Wrong process binding to service ports |
| **UnauthorizedFlowBurst** | 🟠 High | >1 unauthorized flow/sec | 30s | Burst of connections to unknown services |
| **HighFanoutActivity** | 🟡 Medium | >0.1 fanout events/sec | 1m | Potential network scanning detection |
| **SlowConnectionPattern** | 🟡 Medium | >0.5 slow connections/sec | 2m | Port scanning or network issues |
| **EBPFExporterDown** | ⚪ Warning | Exporter unreachable | 30s | Monitoring health check |
| **NoSecurityEventsReported** | ℹ️ Info | Zero events | 5m | Monitor health check |

**Key Features:**
- Rate-based detection prevents false positives from one-off events
- Configurable "for" duration reduces alert flapping
- Detailed annotations provide context for incident response
- Categorized by severity and event type

### 2. Enhanced Grafana Dashboard

Added 4 new panels to visualize alerting status:

**Panel 6: 🚨 Lateral Movement** (Stat)
- Shows count of lateral movement alerts
- Red background when alerts present
- Positioned prominently at top of dashboard

**Panel 7: ⚠️ Process Port Mismatch** (Stat)
- Color-coded thresholds: green (<50), orange (50-99), red (100+)
- Indicates process-port mismatch severity

**Panel 8: 🔥 Active Prometheus Alerts** (Alert List)
- Live list of all firing and pending alerts
- Grouped by alertname and severity
- Shows alert details and descriptions

**Panel 9: Alert Rate Trends** (Time Series)
- Tracks per-second rate for top 3 alert types
- Helps identify attack patterns over time
- 5-minute rate window for smoothing

**Panel 10: 🔔 Firing Alerts Count** (Stat)
- Total count of currently firing alerts
- Color-coded: green (0), yellow (1-4), red (5+)
- Includes sparkline graph

### 3. Configuration Updates

**prometheus.yml**
```yaml
rule_files:
  - /etc/prometheus/alert-rules.yml

scrape_configs:
  - job_name: "ebpf-monitor"  # Renamed for consistency
```

**docker-compose.yml**
```yaml
volumes:
  - ./prometheus/alert-rules.yml:/etc/prometheus/alert-rules.yml:ro
```

### 4. Documentation

**observability/README.md** - Comprehensive guide including:
- Alert rules table with descriptions
- How to view alerts in Prometheus and Grafana
- Dashboard panel descriptions
- Testing workflow
- Troubleshooting section

### 5. Testing Script

**test-alerting.sh** - Automated end-to-end validation:
1. Starts Prometheus + Grafana
2. Verifies alert rules loaded
3. Runs attack simulation
4. Starts metrics exporter
5. Waits for alerts to fire
6. Reports results with color-coded output
7. Provides access URLs

## Files Modified

```
/home/inba/SIA_BANK/
├── observability/
│   ├── docker-compose.yml              [MODIFIED] - Added alert-rules volume mount
│   ├── prometheus/
│   │   ├── prometheus.yml              [MODIFIED] - Added rule_files config
│   │   └── alert-rules.yml             [NEW] - 7 alert rules definition
│   ├── grafana/
│   │   └── dashboards/
│   │       └── ebpf-overview.json      [MODIFIED] - Added 4 alert panels
│   └── README.md                       [MODIFIED] - Comprehensive alerting docs
└── test-alerting.sh                    [NEW] - E2E testing script
```

## How It Works

```
┌─────────────────┐
│  eBPF Monitor   │ Generates security events
└────────┬────────┘
         │ JSONL
         ▼
┌─────────────────┐
│ Metrics Exporter│ Exposes /metrics endpoint
└────────┬────────┘
         │ HTTP scrape (5s interval)
         ▼
┌─────────────────┐
│   Prometheus    │ Evaluates alert rules (5s interval)
│                 │ • Checks rate thresholds
│                 │ • Applies "for" durations
│                 │ • Sets alert states
└────────┬────────┘
         │ Alert state
         ▼
┌─────────────────┐
│    Grafana      │ Visualizes alerts
│                 │ • Alert list panel
│                 │ • Color-coded stat panels
│                 │ • Rate trend graphs
└─────────────────┘
```

## Usage

### Quick Start

```bash
cd /home/inba/SIA_BANK
./test-alerting.sh
```

This will:
- Start the entire stack
- Generate attack traffic
- Wait for alerts to fire
- Show results
- Keep services running until you press Enter

### Manual Workflow

```bash
# 1. Start observability stack
cd /home/inba/SIA_BANK/observability
docker compose up -d

# 2. Generate events
cd /home/inba/SIA_BANK
sudo ./demo-ebpf-attack.sh &

# 3. Start exporter
./start-ebpf-exporter.sh &

# 4. Wait 30 seconds for alerts

# 5. View alerts
# Prometheus: http://localhost:9090/alerts
# Grafana: http://localhost:3000
```

### Accessing Alerts

**Prometheus Alert Page**: http://localhost:9090/alerts
- Shows all alert rules and their states
- Inactive (green) → Pending (yellow) → Firing (red)
- Click alert name to see query
- View annotations for context

**Grafana Dashboard**: http://localhost:3000
- Login: admin/admin
- Dashboard: "eBPF Security Monitoring"
- Check the "🔥 Active Prometheus Alerts" panel
- Red/orange stat panels indicate active threats

## Expected Behavior

After running an attack simulation:

1. **Within 15 seconds**: `LateralMovementDetected` alert fires
   - Dashboard lateral movement panel turns red
   - Alert appears in active alerts list

2. **Within 30 seconds**: `ProcessPortMismatchHigh` alert fires
   - Process mismatch panel shows count with orange/red background
   - Alert rate trend shows spike

3. **Within 1-2 minutes**: Other alerts may fire depending on attack patterns
   - `UnauthorizedFlowBurst`
   - `HighFanoutActivity`
   - `SlowConnectionPattern`

## Alert Configuration

All alert rules are defined in:
```
/home/inba/SIA_BANK/observability/prometheus/alert-rules.yml
```

To modify thresholds:
1. Edit the `expr` field (e.g., change `> 0` to `> 10`)
2. Edit the `for` duration (e.g., change `15s` to `1m`)
3. Restart Prometheus: `docker compose restart prometheus`

## Troubleshooting

### Alerts not firing

**Check exporter metrics**:
```bash
curl http://localhost:9110/metrics | grep ebpf_alerts_total
```
Expected: Non-zero values for alert types

**Check Prometheus scraping**:
- Visit http://localhost:9090/targets
- Target "ebpf-monitor" should show "UP" status
- Last scrape should be recent (<5s ago)

**Check alert rules loaded**:
- Visit http://localhost:9090/rules
- Should see "ebpf_security_alerts" group with 7 rules

**Check alert evaluation**:
```bash
curl -s http://localhost:9090/api/v1/alerts | python3 -m json.tool
```

### Alert rules not loading

**Verify file exists**:
```bash
ls -l observability/prometheus/alert-rules.yml
```

**Validate YAML syntax**:
```bash
docker exec sia-prometheus promtool check rules /etc/prometheus/alert-rules.yml
```

**Check Prometheus logs**:
```bash
docker logs sia-prometheus
```

### Dashboard not showing alerts

**Refresh dashboard**:
- Dashboard auto-refreshes every 5 seconds
- Manual refresh: Click refresh icon in top-right

**Check data source**:
- Settings → Data Sources → Prometheus
- Should show "Data source is working"

**Verify panel queries**:
- Edit a panel
- Check "Query" tab
- Click "Run queries" to test

## Benefits

✅ **Immediate threat detection** - Alerts fire within seconds of detection  
✅ **Reduced false positives** - Rate-based thresholds and "for" durations  
✅ **Clear severity levels** - Prioritize response to critical alerts  
✅ **Contextual information** - Annotations explain what each alert means  
✅ **Visual indicators** - Color-coded dashboard panels for quick assessment  
✅ **Historical trends** - Rate graphs show attack patterns over time  
✅ **Monitoring health** - Alerts when monitoring system itself has issues  

## Next Steps (Optional Enhancements)

1. **Alertmanager Integration**
   - Add Alertmanager container
   - Configure silence rules
   - Set up notification channels (Slack, email, PagerDuty)

2. **Custom Alert Receivers**
   - Webhook to security SIEM
   - Integration with incident management platforms
   - Automated response playbooks

3. **Advanced Dashboards**
   - Heatmap visualization
   - Network topology graphs
   - Alert correlation timeline

4. **Alert Tuning**
   - Adjust thresholds based on baseline traffic
   - Add time-based rules (e.g., after-hours alerts)
   - Create composite alerts (multiple conditions)

## Summary

The eBPF monitoring system now includes a fully automated alerting pipeline:
- **7 Prometheus alert rules** covering critical to informational events
- **10 Grafana dashboard panels** with real-time alert visualization
- **Validated configuration** with working Docker compose setup
- **Comprehensive documentation** for operation and troubleshooting
- **Automated testing** via test-alerting.sh script

The system is production-ready and can detect security threats in real-time with configurable thresholds and clear severity levels.
