# eBPF Runtime Monitoring Layer

This module adds a kernel-level runtime security and observability layer to the SIA_BANK fintech microservices platform.

## Why this exists

PQC-enabled TLS (ML-KEM / ML-DSA) protects confidentiality and integrity, but it does not show runtime communication behavior between services. This eBPF module adds low-overhead telemetry without changing Java microservice code.

## Monitoring Capabilities

### 1. TCP Connection Monitor (`monitor_runtime.py`)
- Service-to-service TCP connect/close events from kernel probes
- Source and destination service mapping using known ports
- Connect latency (`connectLatencyMs`) as handshake/connection health proxy
- TLS candidate flows (ports listed in `service_map.json`)
- Unauthorized service communication edges
- Potential lateral movement bursts
- Process-to-port mismatch (service impersonation signal)

### 2. SSL/TLS Traffic Monitor (`monitor_ssl_traffic.py`) ⭐ NEW
- **Pre-encryption/post-decryption visibility**: Hooks into SSL library functions
- **SSL_read/SSL_write capture**: Monitors actual encrypted traffic patterns
- **TLS handshake tracking**: Cipher suites, TLS versions, handshake duration
- **Per-service traffic analysis**: Bytes sent/received, connection counts
- **PQC awareness**: Detects ML-KEM/ML-DSA usage, alerts on classical crypto fallback
- **Anomaly detection**: Excessive data transfer, unusual handshake patterns
- **Zero code changes**: Uses eBPF uprobes - no application modification required

## What it monitors

- Service-to-service TCP connect/close events from kernel probes
- Source and destination service mapping using known ports
- Connect latency (`connectLatencyMs`) as handshake/connection health proxy
- TLS candidate flows (ports listed in `service_map.json`)
- Unauthorized service communication edges
- Potential lateral movement bursts
- Process-to-port mismatch (service impersonation signal)

## Components

### TCP Connection Monitoring
- `monitor_runtime.py` — BCC/eBPF collector + anomaly analysis engine
- `service_map.json` — service/flow policy and thresholds
- `export_prometheus_metrics.py` — Prometheus metrics exporter (port 9110)

### SSL/TLS Traffic Monitoring ⭐ NEW
- `monitor_ssl_traffic.py` — SSL/TLS traffic observer with eBPF uprobes
- `tls_service_map.json` — TLS-specific configuration and thresholds
- `export_ssl_metrics.py` — SSL metrics exporter for Prometheus (port 9100)

### Startup Scripts
- `../start-ebpf-monitor.sh` — Start TCP monitor
- `../start-ebpf-ssl-monitor.sh` — Start SSL/TLS monitor
### Quick Start (Complete Stack)

From repository root:

```bash
sudo ./start-ebpf-monitoring-stack.sh
```

This starts both TCP and SSL/TLS monitors with Prometheus exporters.

### TCP Connection Monitor Only

```bash
chmod +x start-ebpf-monitor.sh
chmod +x ebpf/monitor_runtime.py
sudo ./start-ebpf-monitor.sh
```

### SSL/TLS Traffic Monitor Only

```bash
chmod +x start-ebpf-ssl-mo - TCP connection events
- `logs/ebpf-ssl-traffic.jsonl` - SSL/TLS traffic events

## Metrics Export

Export metrics to Prometheus for Grafana dashboards:

```bash
# TCP metrics on port 9110
python3 ebpf/export_prometheus_metrics.py \
    --input logs/ebpf-events.jsonl \
    --port 9110

# SSL metrics on port 9100
python3 ebpf/export_ssl_metrics.py \
    --input logs/ebpf-ssl-traffic.jsonl \
    --port 9100
```

Access metrics:
- TCP: http://localhost:9110/metrics
- SSL: http://localhost:9100/metrics

## Event shape

### TCP Connection Event

Each TCP event includes:

- `timestamp`
- `eventType` (`CONNECT` or `CLOSE`)
- `pid`, `uid`, `process`
- `sourceIp`, `destinationIp`, `sport`, `dport`
- `sourceService`, `destinationService`
- `connectLatencyMs`
- `tlsCandidate`, `tlsHandshakeEstimateMs`
- `alerts[]` (if anomaly rules trigger)
**TCP Monitor**: Captures metadata only, not decrypted payloads
- **SSL/TLS Monitor**: Can capture plaintext data (use `--capture-data` flag - SECURITY SENSITIVE!)
- TLS metadata is inferred from port policy and connection timing; no TLS termination is required
- Run with root privileges to attach kernel probes
- If your service ports differ, update `service_map.json` and `tls_service_map.json`
- Java applications using BouncyCastle may require Conscrypt for SSL monitoring

## Documentation

- **[EBPF_SSL_MONITORING_GUIDE.md](../EBPF_SSL_MONITORING_GUIDE.md)** - Complete SSL/TLS monitoring guide
- **[EBPF_MONITORING_QUICK_REFERENCE.md](../EBPF_MONITORING_QUICK_REFERENCE.md)** - Quick reference with common commands
- **[EBPF_INTEGRATION_GUIDE.md](../EBPF_INTEGRATION_GUIDE.md)** - General eBPF integration details

## Architecture

```
Microservices (Java with TLS/PQC)
         ↓
   eBPF Monitors
    ├─ TCP Monitor (kernel probes)
    └─ SSL Monitor (uprobes on libssl)
         ↓
   Prometheus Exporters
    ├─ TCP: :9110/metrics
    └─ SSL: :9100/metrics
         ↓
   Prometheus → Grafana Dashboards
```

- `timestamp`
- `eventType` (`SSL_WRITE`, `SSL_READ`, `SSL_HANDSHAKE`)
- `pid`, `tid`, `uid`, `comm`
- `service`
- `dataLen` - bytes transferred
- `sslSessionId` - SSL session identifier
- `tlsVersion`, `cipherSuite` (for handshake events)
- `trafficStats` - aggregated per-service statistics
- `alerts[]` - anomaly detections
chmod +x ebpf/monitor_runtime.py
sudo ./start-ebpf-monitor.sh
```

The monitor prints JSON events to stdout and writes JSONL logs to:

- `logs/ebpf-events.jsonl`

## Event shape

Each event includes:

- `timestamp`
- `eventType` (`CONNECT` or `CLOSE`)
- `pid`, `uid`, `process`
- `sourceIp`, `destinationIp`, `sport`, `dport`
- `sourceService`, `destinationService`
- `connectLatencyMs`
- `tlsCandidate`, `tlsHandshakeEstimateMs`
- `alerts[]` (if anomaly rules trigger)

## Notes

- This captures metadata, not decrypted payloads.
- TLS metadata is inferred from port policy and connection timing; no TLS termination is required.
- Run with root privileges to attach kernel probes.
- If your service ports differ, update `service_map.json`.

## One-line novelty statement

"This work introduces an eBPF-based kernel-level monitoring framework for PQC-secured fintech microservice architectures, enabling real-time detection of anomalous service communication without modifying application code."
