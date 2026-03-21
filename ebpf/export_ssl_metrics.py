#!/usr/bin/env python3
"""
Prometheus Metrics Exporter for eBPF SSL/TLS Traffic Monitor

This module reads JSONL logs from the eBPF SSL/TLS traffic monitor and
exports metrics to Prometheus for visualization in Grafana.

Metrics exported:
- ssl_traffic_bytes_sent_total: Total bytes sent per service
- ssl_traffic_bytes_received_total: Total bytes received per service
- ssl_handshakes_total: Total TLS handshake count per service
- ssl_connections_active: Active SSL connections per service
- ssl_handshake_duration_seconds: Histogram of handshake durations
- ssl_tls_version_info: TLS version usage per service
- ssl_cipher_suite_info: Cipher suite usage per service
- ssl_anomalies_total: Total anomaly detections per type and service
"""

import argparse
import json
import time
from collections import defaultdict
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from threading import Thread, Lock
import os


class MetricsCollector:
    def __init__(self):
        self.lock = Lock()
        self.metrics = {
            "bytes_sent": defaultdict(int),
            "bytes_received": defaultdict(int),
            "handshakes": defaultdict(int),
            "connections": defaultdict(int),
            "tls_versions": defaultdict(lambda: defaultdict(int)),
            "cipher_suites": defaultdict(lambda: defaultdict(int)),
            "anomalies": defaultdict(lambda: defaultdict(int)),
            "handshake_durations": defaultdict(list),
        }
        self.last_update = datetime.now()
    
    def process_event(self, event):
        with self.lock:
            service = event.get("service", "unknown")
            event_type = event.get("eventType", "")
            
            if event_type == "SSL_WRITE":
                self.metrics["bytes_sent"][service] += event.get("dataLen", 0)
            elif event_type == "SSL_READ":
                self.metrics["bytes_received"][service] += event.get("dataLen", 0)
            elif event_type == "SSL_HANDSHAKE":
                self.metrics["handshakes"][service] += 1
                self.metrics["connections"][service] += 1
                
                # Track TLS version
                tls_version = event.get("tlsVersion", "unknown")
                self.metrics["tls_versions"][service][tls_version] += 1
                
                # Track cipher suite
                cipher_suite = event.get("cipherSuite", "unknown")
                self.metrics["cipher_suites"][service][cipher_suite] += 1
                
                # Track handshake duration
                duration_us = event.get("handshakeDurationUs", 0)
                if duration_us > 0:
                    self.metrics["handshake_durations"][service].append(duration_us / 1000000.0)
            
            # Process alerts/anomalies
            alerts = event.get("alerts", [])
            for alert in alerts:
                alert_type = alert.get("type", "unknown")
                self.metrics["anomalies"][service][alert_type] += 1
            
            self.last_update = datetime.now()
    
    def get_prometheus_metrics(self):
        """Generate Prometheus-formatted metrics"""
        with self.lock:
            lines = []

            # Build a stable service set so all core metrics are always present.
            services = set()
            services.update(self.metrics["bytes_sent"].keys())
            services.update(self.metrics["bytes_received"].keys())
            services.update(self.metrics["handshakes"].keys())
            services.update(self.metrics["connections"].keys())
            services.update(self.metrics["tls_versions"].keys())
            services.update(self.metrics["cipher_suites"].keys())
            services.update(self.metrics["anomalies"].keys())
            services.update(self.metrics["handshake_durations"].keys())
            
            # Bytes sent
            lines.append("# HELP ssl_traffic_bytes_sent_total Total bytes sent over SSL/TLS per service")
            lines.append("# TYPE ssl_traffic_bytes_sent_total counter")
            for service, value in self.metrics["bytes_sent"].items():
                lines.append(f'ssl_traffic_bytes_sent_total{{service="{service}"}} {value}')
            
            # Bytes received
            lines.append("# HELP ssl_traffic_bytes_received_total Total bytes received over SSL/TLS per service")
            lines.append("# TYPE ssl_traffic_bytes_received_total counter")
            for service, value in self.metrics["bytes_received"].items():
                lines.append(f'ssl_traffic_bytes_received_total{{service="{service}"}} {value}')
            
            # Handshakes
            lines.append("# HELP ssl_handshakes_total Total TLS handshakes per service")
            lines.append("# TYPE ssl_handshakes_total counter")
            for service in services:
                value = self.metrics["handshakes"].get(service, 0)
                lines.append(f'ssl_handshakes_total{{service="{service}"}} {value}')
            
            # Active connections
            lines.append("# HELP ssl_connections_active Active SSL connections per service")
            lines.append("# TYPE ssl_connections_active gauge")
            for service in services:
                value = self.metrics["connections"].get(service, 0)
                lines.append(f'ssl_connections_active{{service="{service}"}} {value}')
            
            # TLS versions
            lines.append("# HELP ssl_tls_version_info TLS version usage per service")
            lines.append("# TYPE ssl_tls_version_info counter")
            for service in services:
                versions = self.metrics["tls_versions"].get(service, {})
                if versions:
                    for version, count in versions.items():
                        lines.append(f'ssl_tls_version_info{{service="{service}",version="{version}"}} {count}')
                else:
                    lines.append(f'ssl_tls_version_info{{service="{service}",version="unknown"}} 0')
            
            # Cipher suites
            lines.append("# HELP ssl_cipher_suite_info Cipher suite usage per service")
            lines.append("# TYPE ssl_cipher_suite_info counter")
            for service in services:
                suites = self.metrics["cipher_suites"].get(service, {})
                if suites:
                    for suite, count in suites.items():
                        lines.append(f'ssl_cipher_suite_info{{service="{service}",cipher="{suite}"}} {count}')
                else:
                    lines.append(f'ssl_cipher_suite_info{{service="{service}",cipher="unknown"}} 0')
            
            # Anomalies
            lines.append("# HELP ssl_anomalies_total Total anomaly detections per type and service")
            lines.append("# TYPE ssl_anomalies_total counter")
            for service, anomaly_types in self.metrics["anomalies"].items():
                for anomaly_type, count in anomaly_types.items():
                    lines.append(f'ssl_anomalies_total{{service="{service}",type="{anomaly_type}"}} {count}')
            
            # Handshake duration percentiles
            lines.append("# HELP ssl_handshake_duration_seconds TLS handshake duration in seconds")
            lines.append("# TYPE ssl_handshake_duration_seconds summary")
            for service in services:
                durations = self.metrics["handshake_durations"].get(service, [])
                if durations:
                    sorted_durations = sorted(durations)
                    p50 = sorted_durations[len(sorted_durations) // 2]
                    p90 = sorted_durations[int(len(sorted_durations) * 0.9)]
                    p99 = sorted_durations[int(len(sorted_durations) * 0.99)]
                    
                    lines.append(f'ssl_handshake_duration_seconds{{service="{service}",quantile="0.5"}} {p50:.6f}')
                    lines.append(f'ssl_handshake_duration_seconds{{service="{service}",quantile="0.9"}} {p90:.6f}')
                    lines.append(f'ssl_handshake_duration_seconds{{service="{service}",quantile="0.99"}} {p99:.6f}')
                    lines.append(f'ssl_handshake_duration_seconds_sum{{service="{service}"}} {sum(durations):.6f}')
                    lines.append(f'ssl_handshake_duration_seconds_count{{service="{service}"}} {len(durations)}')
                else:
                    lines.append(f'ssl_handshake_duration_seconds{{service="{service}",quantile="0.5"}} 0')
                    lines.append(f'ssl_handshake_duration_seconds{{service="{service}",quantile="0.9"}} 0')
                    lines.append(f'ssl_handshake_duration_seconds{{service="{service}",quantile="0.99"}} 0')
                    lines.append(f'ssl_handshake_duration_seconds_sum{{service="{service}"}} 0')
                    lines.append(f'ssl_handshake_duration_seconds_count{{service="{service}"}} 0')
            
            # Exporter metadata
            lines.append("# HELP ssl_exporter_last_update_timestamp_seconds Last update time")
            lines.append("# TYPE ssl_exporter_last_update_timestamp_seconds gauge")
            lines.append(f'ssl_exporter_last_update_timestamp_seconds {self.last_update.timestamp()}')
            
            return "\n".join(lines) + "\n"


class MetricsHandler(BaseHTTPRequestHandler):
    collector = None
    
    def do_GET(self):
        if self.path == "/metrics":
            metrics = self.collector.get_prometheus_metrics()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.end_headers()
            self.wfile.write(metrics.encode("utf-8"))
        elif self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK\n")
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress HTTP request logs
        pass


def tail_jsonl_file(filepath, collector):
    """Tail JSONL file and process new events"""
    if not os.path.exists(filepath):
        print(f"Waiting for log file: {filepath}")
        while not os.path.exists(filepath):
            time.sleep(1)
    
    print(f"Tailing log file: {filepath}")
    
    with open(filepath, "r") as f:
        # Seek to beginning of file to process all existing events first
        f.seek(0, 0)
        
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.1)
                continue
            
            line = line.strip()
            if not line:
                continue
            
            try:
                event = json.loads(line)
                collector.process_event(event)
            except json.JSONDecodeError as e:
                print(f"Error parsing JSON: {e}")
                continue


def main():
    parser = argparse.ArgumentParser(
        description="Prometheus metrics exporter for eBPF SSL/TLS traffic monitor"
    )
    parser.add_argument("--input", required=True, 
                       help="Path to JSONL log file from SSL monitor")
    parser.add_argument("--port", type=int, default=9100,
                       help="Port to expose metrics on (default: 9100)")
    parser.add_argument("--host", default="0.0.0.0",
                       help="Host to bind to (default: 0.0.0.0)")
    args = parser.parse_args()
    
    # Initialize metrics collector
    collector = MetricsCollector()
    MetricsHandler.collector = collector
    
    # Start HTTP server in a separate thread
    server = HTTPServer((args.host, args.port), MetricsHandler)
    server_thread = Thread(target=server.serve_forever, daemon=True)
    server_thread.start()
    
    print(f"Prometheus metrics exporter started on {args.host}:{args.port}")
    print(f"Metrics endpoint: http://{args.host}:{args.port}/metrics")
    print(f"Health endpoint: http://{args.host}:{args.port}/health")
    print("")
    
    # Tail log file and process events
    try:
        tail_jsonl_file(args.input, collector)
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
