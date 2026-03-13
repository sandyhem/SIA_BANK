#!/usr/bin/env python3
import argparse
import ctypes as ct
import json
import os
import signal
import socket
import struct
import sys
import time
from collections import defaultdict, deque
from datetime import datetime, timezone

try:
    from bcc import BPF
except ImportError as exc:
    print("Missing dependency: python3-bpfcc (BCC Python bindings)", file=sys.stderr)
    print("Install on Ubuntu/Debian: sudo apt-get install -y bpfcc-tools python3-bpfcc linux-headers-$(uname -r)", file=sys.stderr)
    raise SystemExit(1) from exc


BPF_PROGRAM = r"""
#include <uapi/linux/ptrace.h>
#include <uapi/linux/in.h>
#include <bcc/proto.h>

#define TCP_ESTABLISHED 1
#define TCP_SYN_SENT 2
#define TCP_CLOSE 7

struct event_t {
    u64 ts_ns;
    u32 pid;
    u32 uid;
    u32 saddr;
    u32 daddr;
    u16 sport;
    u16 dport;
    u32 netns;
    u32 delta_ms;
    u8 event_type;
    char comm[TASK_COMM_LEN];
};

BPF_PERF_OUTPUT(events);

TRACEPOINT_PROBE(sock, inet_sock_set_state) {
    if (args->protocol != IPPROTO_TCP) {
        return 0;
    }

    if (args->family != AF_INET) {
        return 0;
    }

    struct event_t event = {};
    u64 id = bpf_get_current_pid_tgid();

    event.ts_ns = bpf_ktime_get_ns();
    event.pid = id >> 32;
    event.uid = bpf_get_current_uid_gid();
    bpf_probe_read_kernel(&event.saddr, sizeof(event.saddr), args->saddr);
    bpf_probe_read_kernel(&event.daddr, sizeof(event.daddr), args->daddr);
    event.sport = args->sport;
    event.dport = args->dport;
    event.netns = 0;
    event.delta_ms = 0;
    bpf_get_current_comm(&event.comm, sizeof(event.comm));

    if (args->oldstate == TCP_SYN_SENT && args->newstate == TCP_ESTABLISHED) {
        event.event_type = 1;
    } else if (args->newstate == TCP_CLOSE) {
        event.event_type = 2;
    } else {
        return 0;
    }

    events.perf_submit(args, &event, sizeof(event));
    return 0;
}
"""


class Event(ct.Structure):
    _fields_ = [
        ("ts_ns", ct.c_ulonglong),
        ("pid", ct.c_uint),
        ("uid", ct.c_uint),
        ("saddr", ct.c_uint),
        ("daddr", ct.c_uint),
        ("sport", ct.c_ushort),
        ("dport", ct.c_ushort),
        ("netns", ct.c_uint),
        ("delta_ms", ct.c_uint),
        ("event_type", ct.c_ubyte),
        ("comm", ct.c_char * 16),
    ]


class RuntimeAnalyzer:
    def __init__(self, config):
        self.config = config
        self.port_to_service = {svc["port"]: svc for svc in config["services"]}
        self.allowed_flows = {(flow["source"], flow["destination"]) for flow in config["allowedFlows"]}
        self.tls_candidate_ports = set(config.get("tlsCandidatePorts", []))
        thresholds = config.get("anomalyThresholds", {})
        self.max_distinct_peers = thresholds.get("maxDistinctPeersPerMinute", 20)
        self.slow_connect_ms = thresholds.get("slowConnectMs", 150)
        self.unknown_burst = thresholds.get("unknownFlowBurstPerMinute", 10)

        self.peer_windows = defaultdict(lambda: deque())
        self.unknown_flow_windows = defaultdict(lambda: deque())

    def _service_name(self, port):
        svc = self.port_to_service.get(port)
        return svc["name"] if svc else f"unknown:{port}"

    def analyze(self, event):
        src_service = self._service_name(event["sport"])
        dst_service = self._service_name(event["dport"])
        edge = (src_service, dst_service)

        timestamp = time.time()
        peer_key = (src_service, event["pid"])
        self.peer_windows[peer_key].append((timestamp, dst_service))
        while self.peer_windows[peer_key] and timestamp - self.peer_windows[peer_key][0][0] > 60:
            self.peer_windows[peer_key].popleft()

        distinct_peers = {item[1] for item in self.peer_windows[peer_key]}
        alerts = []

        if edge not in self.allowed_flows and not src_service.startswith("unknown"):
            normalized_dst_for_burst = "unknown:any" if dst_service.startswith("unknown:") else dst_service
            unknown_key = f"{src_service}->{normalized_dst_for_burst}"
            self.unknown_flow_windows[unknown_key].append(timestamp)
            while self.unknown_flow_windows[unknown_key] and timestamp - self.unknown_flow_windows[unknown_key][0] > 60:
                self.unknown_flow_windows[unknown_key].popleft()

            alerts.append({
                "type": "UNAUTHORIZED_FLOW",
                "severity": "high",
                "message": f"Observed unexpected service flow {src_service} -> {dst_service}",
                "flow": {"source": src_service, "destination": dst_service},
                "count_last_minute": len(self.unknown_flow_windows[unknown_key]),
            })

            if len(self.unknown_flow_windows[unknown_key]) >= self.unknown_burst:
                alerts.append({
                    "type": "LATERAL_MOVEMENT_PATTERN",
                    "severity": "critical",
                    "message": f"Burst of unauthorized communications on {unknown_key}",
                    "flow": {"source": src_service, "destination": dst_service},
                    "count_last_minute": len(self.unknown_flow_windows[unknown_key]),
                })

        if len(distinct_peers) > self.max_distinct_peers:
            alerts.append({
                "type": "HIGH_FAN_OUT",
                "severity": "medium",
                "message": f"Process PID {event['pid']} in {src_service} contacted too many peers in 60s",
                "distinct_peers": len(distinct_peers),
            })

        if event["delta_ms"] >= self.slow_connect_ms:
            alerts.append({
                "type": "SLOW_CONNECT",
                "severity": "low",
                "message": f"Slow connect latency {event['delta_ms']}ms detected",
                "connect_latency_ms": event["delta_ms"],
                "flow": {"source": src_service, "destination": dst_service},
            })

        expected_processes = self.port_to_service.get(event["sport"], {}).get("expectedProcesses", [])
        if expected_processes:
            comm = event["comm"]
            if all(proc not in comm for proc in expected_processes):
                alerts.append({
                    "type": "PROCESS_PORT_MISMATCH",
                    "severity": "high",
                    "message": f"Potential service impersonation: process {comm} using port mapped to {src_service}",
                    "process": comm,
                    "expected": expected_processes,
                    "service": src_service,
                })

        event["sourceService"] = src_service
        event["destinationService"] = dst_service
        event["tlsCandidate"] = event["dport"] in self.tls_candidate_ports or event["sport"] in self.tls_candidate_ports
        event["tlsHandshakeEstimateMs"] = event["delta_ms"] if event["tlsCandidate"] else None
        event["alerts"] = alerts

        return event


def inet_ntoa(num):
    return socket.inet_ntoa(struct.pack("I", num))


def iso_now_from_ns(ns):
    return datetime.fromtimestamp(ns / 1_000_000_000, tz=timezone.utc).isoformat()


def load_config(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def print_summary(stats):
    print("\n=== eBPF Runtime Summary ===")
    print(f"total_events={stats['total_events']} alerts={stats['total_alerts']}")
    for key, value in sorted(stats["flows"].items(), key=lambda item: item[1], reverse=True)[:10]:
        print(f"flow={key} count={value}")


def main():
    parser = argparse.ArgumentParser(description="eBPF runtime monitor for fintech microservices")
    parser.add_argument("--config", required=True, help="Path to service map JSON")
    parser.add_argument("--output", default="", help="Optional JSONL output file")
    parser.add_argument("--summary-interval", type=int, default=15, help="Summary print interval in seconds")
    args = parser.parse_args()

    if os.geteuid() != 0:
        print("Run as root: eBPF probes need elevated privileges.", file=sys.stderr)
        raise SystemExit(1)

    config = load_config(args.config)
    analyzer = RuntimeAnalyzer(config)

    bpf = BPF(text=BPF_PROGRAM)

    out_handle = None
    if args.output:
        os.makedirs(os.path.dirname(args.output), exist_ok=True)
        out_handle = open(args.output, "a", encoding="utf-8")

    stats = {
        "total_events": 0,
        "total_alerts": 0,
        "flows": defaultdict(int),
    }

    stop = {"value": False}

    def handle_signal(_sig, _frame):
        stop["value"] = True

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    last_summary = time.time()

    def handle_event(_cpu, data, _size):
        event = ct.cast(data, ct.POINTER(Event)).contents

        payload = {
            "timestamp": iso_now_from_ns(event.ts_ns),
            "eventType": "CONNECT" if event.event_type == 1 else "CLOSE",
            "pid": int(event.pid),
            "uid": int(event.uid),
            "process": event.comm.decode("utf-8", errors="replace").strip("\x00"),
            "sourceIp": inet_ntoa(event.saddr),
            "destinationIp": inet_ntoa(event.daddr),
            "sport": int(event.sport),
            "dport": int(event.dport),
            "connectLatencyMs": int(event.delta_ms),
            "networkNamespace": int(event.netns),
        }

        analyzed = analyzer.analyze({
            "pid": payload["pid"],
            "comm": payload["process"],
            "sport": payload["sport"],
            "dport": payload["dport"],
            "delta_ms": payload["connectLatencyMs"],
        })

        payload.update({
            "sourceService": analyzed["sourceService"],
            "destinationService": analyzed["destinationService"],
            "tlsCandidate": analyzed["tlsCandidate"],
            "tlsHandshakeEstimateMs": analyzed["tlsHandshakeEstimateMs"],
            "alerts": analyzed["alerts"],
        })

        flow_key = f"{payload['sourceService']}->{payload['destinationService']}"
        stats["total_events"] += 1
        stats["flows"][flow_key] += 1
        if payload["alerts"]:
            stats["total_alerts"] += len(payload["alerts"])

        line = json.dumps(payload)
        print(line)
        if out_handle:
            out_handle.write(line + "\n")
            out_handle.flush()

    bpf["events"].open_perf_buffer(handle_event)

    print("eBPF monitor started. Press Ctrl+C to stop.")
    while not stop["value"]:
        bpf.perf_buffer_poll(timeout=1000)
        if time.time() - last_summary >= args.summary_interval:
            print_summary(stats)
            last_summary = time.time()

    print_summary(stats)
    if out_handle:
        out_handle.close()


if __name__ == "__main__":
    main()
