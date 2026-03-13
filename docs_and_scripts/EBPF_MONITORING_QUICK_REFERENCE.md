# eBPF Encrypted Traffic Monitoring - Quick Reference

## Quick Start

### 1. Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y bpfcc-tools python3-bpfcc linux-headers-$(uname -r)
```

### 2. Start Complete Monitoring Stack

```bash
# Start both TCP and SSL/TLS monitors with Prometheus exporters
sudo ./start-ebpf-monitoring-stack.sh

# Or start individually:
sudo ./start-ebpf-monitor.sh              # TCP connections only
sudo ./start-ebpf-ssl-monitor.sh          # SSL/TLS traffic only
```

### 3. View Metrics

```bash
# TCP connection metrics
curl http://localhost:9110/metrics

# SSL/TLS traffic metrics
curl http://localhost:9100/metrics
```

### 4. View Logs

```bash
# TCP connection events
tail -f logs/ebpf-events.jsonl | jq .

# SSL/TLS traffic events
tail -f logs/ebpf-ssl-traffic.jsonl | jq .
```

---

## Monitor Types

### TCP Connection Monitor
- **What it monitors**: TCP connect/close events, connection metadata
- **Works with**: All microservices (Java, Node.js, etc.)
- **Sees encrypted data**: No (only connection metadata)
- **Use when**: You need general connection visibility
- **Command**: `sudo ./start-ebpf-monitor.sh`

### SSL/TLS Traffic Monitor
- **What it monitors**: SSL_read/SSL_write calls, handshake details
- **Works with**: Applications using OpenSSL/libssl
- **Sees encrypted data**: Yes (plaintext before encryption/after decryption)
- **Use when**: You need deep SSL/TLS inspection
- **Command**: `sudo ./start-ebpf-ssl-monitor.sh`
- **Note**: Java apps using BouncyCastle may not work with this monitor

---

## Key Files

| File | Purpose |
|------|---------|
| `ebpf/monitor_runtime.py` | TCP connection monitor |
| `ebpf/monitor_ssl_traffic.py` | SSL/TLS traffic monitor |
| `ebpf/service_map.json` | TCP monitor configuration |
| `ebpf/tls_service_map.json` | SSL monitor configuration |
| `ebpf/export_prometheus_metrics.py` | TCP metrics exporter |
| `ebpf/export_ssl_metrics.py` | SSL metrics exporter |
| `logs/ebpf-events.jsonl` | TCP connection logs |
| `logs/ebpf-ssl-traffic.jsonl` | SSL/TLS traffic logs |

---

## Common Commands

### Start Services

```bash
# Start microservices first
./start-services.sh

# Start observability stack (Prometheus + Grafana)
cd observability && docker-compose up -d

# Start eBPF monitoring
sudo ./start-ebpf-monitoring-stack.sh
```

### View Live Events

```bash
# TCP connections
sudo python3 ebpf/monitor_runtime.py \
    --config ebpf/service_map.json \
    --output logs/ebpf-events.jsonl

# SSL/TLS traffic
sudo python3 ebpf/monitor_ssl_traffic.py \
    --config ebpf/tls_service_map.json \
    --output logs/ebpf-ssl-traffic.jsonl
```

### Export Metrics to Prometheus

```bash
# TCP metrics on port 9110
python3 ebpf/export_prometheus_metrics.py \
    --input logs/ebpf-events.jsonl \
    --port 9110 &

# SSL metrics on port 9100
python3 ebpf/export_ssl_metrics.py \
    --input logs/ebpf-ssl-traffic.jsonl \
    --port 9100 &
```

### Query Metrics

```bash
# Check TCP metrics
curl -s http://localhost:9110/metrics | grep ebpf

# Check SSL metrics
curl -s http://localhost:9100/metrics | grep ssl

# Health check
curl http://localhost:9110/health
curl http://localhost:9100/health
```

---

## Configuration

### Adjust Anomaly Thresholds

Edit `ebpf/tls_service_map.json`:

```json
{
  "tlsAnomalyThresholds": {
    "maxBytesPerMinute": 10485760,        // 10MB
    "maxHandshakesPerMinute": 100,
    "minHandshakeDurationMs": 10,
    "maxHandshakeDurationMs": 5000
  }
}
```

### Enable Data Capture (Development Only!)

```bash
# WARNING: Captures plaintext data - sensitive!
sudo ./start-ebpf-ssl-monitor.sh --capture-data
```

### Add New Service

Edit `ebpf/tls_service_map.json`:

```json
{
  "services": [
    {
      "name": "my-new-service",
      "port": 8084,
      "expectedProcesses": ["java"],
      "tlsEnabled": true,
      "pqcEnabled": true
    }
  ]
}
```

---

## Grafana Dashboards

### Access Grafana

```bash
# URL: http://localhost:3000
# Default credentials: admin / admin
```

### Import Dashboards

1. Open Grafana → Dashboards → Import
2. Upload JSON files from `observability/grafana/dashboards/`:
   - `ebpf-runtime.json` - TCP connection monitoring
   - `ebpf-ssl-traffic.json` - SSL/TLS traffic monitoring

### Key Panels

**TCP Dashboard:**
- Service-to-service connections
- Connection rates and latency
- Unauthorized flow alerts
- Lateral movement detection

**SSL/TLS Dashboard:**
- Traffic volume (bytes sent/received)
- TLS handshake rates and duration
- Active SSL connections
- TLS version distribution
- Cipher suite distribution
- Anomaly alerts

---

## Troubleshooting

### Issue: "Missing dependency: python3-bpfcc"

```bash
sudo apt-get install -y bpfcc-tools python3-bpfcc linux-headers-$(uname -r)
```

### Issue: "Could not locate OpenSSL library"

```bash
# Find OpenSSL library
ldconfig -p | grep libssl

# Java apps may not use OpenSSL
# Use TCP monitor instead
sudo ./start-ebpf-monitor.sh
```

### Issue: "Error attaching probes"

For Java applications using BouncyCastle (pure Java crypto):
- SSL/TLS monitor won't work (no OpenSSL calls)
- Use TCP connection monitor instead
- Or configure Java to use Conscrypt (OpenSSL provider)

### Issue: No metrics showing up

```bash
# Check if services are running
ps aux | grep java

# Check if monitors are running
ps aux | grep monitor

# Check metrics endpoints
curl http://localhost:9110/metrics
curl http://localhost:9100/metrics

# Check logs for errors
tail -f logs/ebpf-events.jsonl
tail -f logs/ebpf-ssl-traffic.jsonl
```

### Issue: High CPU usage

```bash
# Increase summary interval
sudo ./start-ebpf-ssl-monitor.sh --summary-interval 60

# Disable data capture
# (Remove --capture-data flag)
```

---

## Security Notes

⚠️ **IMPORTANT**: 

1. **Data Capture**: The `--capture-data` flag captures plaintext data
   - Only use in development/debugging
   - Never enable in production without approval
   - Logs contain sensitive information

2. **Access Control**: 
   - Monitors require root privileges
   - Secure log files: `chmod 600 logs/*.jsonl`
   - Restrict log access to authorized personnel

3. **Compliance**:
   - Document monitoring purposes
   - Ensure compliance with data protection regulations
   - Obtain necessary security approvals

---

## Performance Impact

| Monitor Type | CPU Overhead | Memory Overhead | Latency Impact |
|--------------|--------------|-----------------|----------------|
| TCP Monitor | <1% | ~10MB | <0.1ms |
| SSL Monitor | <2% | ~20MB | <1ms |
| Both Monitors | <3% | ~30MB | <1ms |

---

## Metrics Reference

### TCP Connection Metrics

```
ebpf_connections_total{source,destination}    # Total connections
ebpf_connect_latency_seconds{source,quantile} # Connection latency
ebpf_unauthorized_flows_total{source,dest}    # Unauthorized flows
ebpf_active_services                           # Active services
```

### SSL/TLS Traffic Metrics

```
ssl_traffic_bytes_sent_total{service}          # Bytes sent
ssl_traffic_bytes_received_total{service}      # Bytes received
ssl_handshakes_total{service}                  # TLS handshakes
ssl_connections_active{service}                # Active connections
ssl_handshake_duration_seconds{service,quantile} # Handshake duration
ssl_tls_version_info{service,version}          # TLS versions
ssl_cipher_suite_info{service,cipher}          # Cipher suites
ssl_anomalies_total{service,type}              # Anomalies detected
```

---

## Event Format

### TCP Connection Event

```json
{
  "timestamp": "2026-03-08T10:15:30.123456Z",
  "eventType": "CONNECT",
  "pid": 12345,
  "process": "java",
  "sourceService": "auth-service",
  "destinationService": "account-service",
  "sourceIp": "127.0.0.1",
  "destinationIp": "127.0.0.1",
  "sport": 8083,
  "dport": 8081,
  "connectLatencyMs": 2,
  "tlsCandidate": true,
  "alerts": []
}
```

### SSL/TLS Traffic Event

```json
{
  "timestamp": "2026-03-08T10:15:30.234567Z",
  "eventType": "SSL_WRITE",
  "pid": 12345,
  "comm": "java",
  "service": "auth-service",
  "dataLen": 512,
  "sslSessionId": "0x7f8a4c001234",
  "trafficStats": {
    "bytes_sent": 1048576,
    "bytes_received": 2097152,
    "connections": 25,
    "handshakes": 25
  },
  "alerts": []
}
```

---

## Next Steps

1. **Read Full Documentation**: [EBPF_SSL_MONITORING_GUIDE.md](EBPF_SSL_MONITORING_GUIDE.md)
2. **Configure Services**: Edit `ebpf/tls_service_map.json`
3. **Setup Grafana**: Import dashboards from `observability/grafana/dashboards/`
4. **Configure Alerts**: Add Prometheus alerting rules
5. **Review Security**: Ensure compliance with security policies

---

## Support

For detailed information, see:
- [EBPF_SSL_MONITORING_GUIDE.md](EBPF_SSL_MONITORING_GUIDE.md) - Complete SSL/TLS monitoring guide
- [EBPF_INTEGRATION_GUIDE.md](EBPF_INTEGRATION_GUIDE.md) - General eBPF integration
- [ebpf/README.md](ebpf/README.md) - eBPF module documentation
- [RUN_GUIDE.md](RUN_GUIDE.md) - Service startup guide
