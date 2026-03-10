#!/usr/bin/env python3
import argparse
import json
import threading
import time
from collections import Counter, defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer


class MetricsState:
    def __init__(self):
        self.lock = threading.Lock()
        self.total_events = 0
        self.total_alerts = 0
        self.events_by_type = Counter()
        self.alerts_by_type = Counter()
        self.alerts_by_severity = Counter()
        self.flows = Counter()
        self.source_service_alerts = Counter()
        self.last_timestamp = 0.0

    def update_from_event(self, event):
        with self.lock:
            self.total_events += 1
            event_type = event.get("eventType", "UNKNOWN")
            self.events_by_type[event_type] += 1

            source = event.get("sourceService", "unknown")
            destination = event.get("destinationService", "unknown")
            flow_key = f"{source}->{destination}"
            self.flows[flow_key] += 1

            alerts = event.get("alerts", [])
            self.total_alerts += len(alerts)
            for alert in alerts:
                alert_type = alert.get("type", "UNKNOWN")
                severity = alert.get("severity", "unknown")
                self.alerts_by_type[alert_type] += 1
                self.alerts_by_severity[severity] += 1
                self.source_service_alerts[source] += 1

            self.last_timestamp = time.time()

    def render_prometheus(self):
        with self.lock:
            lines = [
                "# HELP ebpf_events_total Total eBPF events processed",
                "# TYPE ebpf_events_total counter",
                f"ebpf_events_total {self.total_events}",
                "# HELP ebpf_alerts_total Total eBPF alerts detected",
                "# TYPE ebpf_alerts_total counter",
                f"ebpf_alerts_total {self.total_alerts}",
                "# HELP ebpf_exporter_last_update_seconds Unix timestamp of last event processed",
                "# TYPE ebpf_exporter_last_update_seconds gauge",
                f"ebpf_exporter_last_update_seconds {self.last_timestamp:.0f}",
                "# HELP ebpf_events_by_type_total Events by eBPF event type",
                "# TYPE ebpf_events_by_type_total counter",
            ]

            for key, value in sorted(self.events_by_type.items()):
                lines.append(f'ebpf_events_by_type_total{{event_type="{key}"}} {value}')

            lines.extend([
                "# HELP ebpf_alerts_by_type_total Alerts by alert type",
                "# TYPE ebpf_alerts_by_type_total counter",
            ])
            for key, value in sorted(self.alerts_by_type.items()):
                lines.append(f'ebpf_alerts_by_type_total{{alert_type="{key}"}} {value}')

            lines.extend([
                "# HELP ebpf_alerts_by_severity_total Alerts by severity",
                "# TYPE ebpf_alerts_by_severity_total counter",
            ])
            for key, value in sorted(self.alerts_by_severity.items()):
                lines.append(f'ebpf_alerts_by_severity_total{{severity="{key}"}} {value}')

            lines.extend([
                "# HELP ebpf_flow_events_total Event count by source and destination service",
                "# TYPE ebpf_flow_events_total counter",
            ])
            for key, value in sorted(self.flows.items()):
                source, destination = key.split("->", 1)
                lines.append(f'ebpf_flow_events_total{{source_service="{source}",destination_service="{destination}"}} {value}')

            lines.extend([
                "# HELP ebpf_source_service_alerts_total Alerts grouped by source service",
                "# TYPE ebpf_source_service_alerts_total counter",
            ])
            for key, value in sorted(self.source_service_alerts.items()):
                lines.append(f'ebpf_source_service_alerts_total{{source_service="{key}"}} {value}')

            lines.append("")
            return "\n".join(lines)


class MetricsHandler(BaseHTTPRequestHandler):
    state = None

    def do_GET(self):
        if self.path not in ("/metrics", "/metrics/"):
            self.send_response(404)
            self.end_headers()
            return

        body = self.state.render_prometheus().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return


def tail_jsonl_file(file_path, state: MetricsState, poll_interval: float, from_beginning: bool):
    with open(file_path, "r", encoding="utf-8") as handle:
        if from_beginning:
            handle.seek(0)
        else:
            handle.seek(0, 2)
        while True:
            line = handle.readline()
            if not line:
                time.sleep(poll_interval)
                continue

            line = line.strip()
            if not line:
                continue

            try:
                payload = json.loads(line)
            except json.JSONDecodeError:
                continue

            state.update_from_event(payload)


def main():
    parser = argparse.ArgumentParser(description="Export eBPF JSONL events as Prometheus metrics")
    parser.add_argument("--input", required=True, help="Path to eBPF JSONL file")
    parser.add_argument("--host", default="0.0.0.0", help="Exporter listen host")
    parser.add_argument("--port", type=int, default=9110, help="Exporter listen port")
    parser.add_argument("--poll-interval", type=float, default=0.5, help="File tail polling interval seconds")
    parser.add_argument("--from-end", action="store_true", help="Start tailing from end of file")
    args = parser.parse_args()

    state = MetricsState()
    MetricsHandler.state = state

    thread = threading.Thread(
        target=tail_jsonl_file,
        args=(args.input, state, args.poll_interval, not args.from_end),
        daemon=True,
    )
    thread.start()

    server = HTTPServer((args.host, args.port), MetricsHandler)
    print(f"eBPF metrics exporter listening on http://{args.host}:{args.port}/metrics")
    server.serve_forever()


if __name__ == "__main__":
    main()
