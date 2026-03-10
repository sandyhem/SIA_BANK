# eBPF Observability Stack (Prometheus + Grafana)

This stack visualizes eBPF runtime security telemetry, alerts, and provides **automated alerting** for critical security events.

## Components

- **eBPF monitor**: writes JSONL events (`logs/ebpf-attack-demo.jsonl`)
- **eBPF Prometheus exporter**: reads JSONL and exposes `/metrics` on port `9110`
- **Prometheus**: scrapes exporter metrics on port `9090` + evaluates alert rules
- **Grafana**: dashboards on port `3000` with alert visualization

## Features

✅ **Real-time monitoring** - 5-second scrape interval  
✅ **Automated alerting** - 7 Prometheus alert rules for security events  
✅ **Visual dashboards** - 10 panels including alert status and active firing alerts  
✅ **Alert categorization** - Critical, High, Medium, Info severity levels  

## 1) Generate eBPF events

```bash
cd /home/inba/SIA_BANK
sudo ./demo-ebpf-attack.sh
```

## 2) Start exporter

```bash
cd /home/inba/SIA_BANK
chmod +x start-ebpf-exporter.sh ebpf/export_prometheus_metrics.py
./start-ebpf-exporter.sh
```

Check metrics:

```bash
curl -s http://localhost:9110/metrics | head
```

## 3) Start Prometheus + Grafana

```bash
cd /home/inba/SIA_BANK/observability
docker compose up -d
```

## 4) Access UI

- **Prometheus**: http://localhost:9090
  - View metrics: Graph tab → `ebpf_alerts_total`
  - **View alerts**: http://localhost:9090/alerts (shows firing/pending alerts)
  
- **Grafana**: http://localhost:3000
  - user: `admin`
  - password: `admin`
  - Dashboard: `eBPF Security Monitoring` (auto-provisioned)

## Alert Rules

The system includes 7 automated alert rules:

| Alert Name | Severity | Trigger | Description |
|------------|----------|---------|-------------|
| **LateralMovementDetected** | 🔴 Critical | Any lateral movement in 1m | Network reconnaissance detected |
| **ProcessPortMismatchHigh** | 🟠 High | >0.5/s for 30s | Unexpected process on service port |
| **UnauthorizedFlowBurst** | 🟠 High | >1/s for 30s | Connections to unregistered services |
| **HighFanoutActivity** | 🟡 Medium | >0.1/s for 1m | Possible network scanning |
| **SlowConnectionPattern** | 🟡 Medium | >0.5/s for 2m | Persistent slow connections |
| **EBPFExporterDown** | ⚪ Warning | Exporter down 30s | Monitoring impaired |
| **NoSecurityEventsReported** | ℹ️ Info | No events 5m | Monitor may be stopped |

### Viewing Alerts

**Prometheus Alerts Page**: http://localhost:9090/alerts
- Shows all alert states (Inactive/Pending/Firing)
- Click alert name for query details
- View annotations for context

**Grafana Dashboard**:
- **🚨 Lateral Movement** panel - Red background when detected
- **⚠️ Process Port Mismatch** panel - Color-coded by count
- **🔥 Active Prometheus Alerts** panel - List of firing alerts
- **🔔 Firing Alerts Count** panel - Total active alerts
- **Alert Rate Trends** - Per-second alert rates over time

## Dashboard Panels

The Grafana dashboard includes:

1. **Total eBPF Events** - Cumulative event count
2. **Total eBPF Alerts** - Cumulative alert count
3. **🚨 Lateral Movement** - Critical alert indicator (red when >0)
4. **⚠️ Process Port Mismatch** - Warning indicator (color-coded)
5. **Alerts by Type** - Time series breakdown
6. **Alerts by Severity** - Time series by severity
7. **Top eBPF Flows** - Most frequent network flows
8. **🔥 Active Prometheus Alerts** - Live firing alerts list
9. **Alert Rate Trends** - Rate analysis for key alert types
10. **🔔 Firing Alerts Count** - Total active alert gauge

## Testing the Alert System

Run an attack simulation and watch alerts fire:

```bash
# Terminal 1: Start exporter
cd /home/inba/SIA_BANK
./start-ebpf-exporter.sh

# Terminal 2: Run attack demo
cd /home/inba/SIA_BANK
sudo ./demo-ebpf-attack.sh

# Terminal 3: Start observability stack
cd /home/inba/SIA_BANK/observability
docker compose up -d

# Wait 15-30 seconds for alerts to fire, then check:
# - Prometheus: http://localhost:9090/alerts
# - Grafana: http://localhost:3000 (eBPF Security Monitoring dashboard)
```

Expected results:
- **LateralMovementDetected** should fire within 15 seconds
- **ProcessPortMismatchHigh** should fire within 30 seconds
- Grafana panels should turn red/orange for critical alerts

## Troubleshooting

### Alerts not firing
1. Verify exporter is running: `curl http://localhost:9110/metrics`
2. Check Prometheus is scraping: http://localhost:9090/targets
3. Verify events exist: `cat logs/ebpf-attack-demo.jsonl | wc -l`
4. Check alert rules loaded: http://localhost:9090/rules

### host.docker.internal not resolving
Ensure Docker compose includes:
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### Exporter showing zero metrics
If exporter starts from file end, restart it to read from beginning:
```bash
pkill -f export_prometheus_metrics
./start-ebpf-exporter.sh
```

## Cleanup

```bash
cd /home/inba/SIA_BANK/observability
docker compose down
pkill -f export_prometheus_metrics
```

## Important Notes

- Keep `start-ebpf-exporter.sh` running while Prometheus scrapes
- Alert evaluation interval is 5 seconds (matches scrape interval)
- Dashboard auto-refreshes every 5 seconds
- Alert rules are defined in `prometheus/alert-rules.yml`
