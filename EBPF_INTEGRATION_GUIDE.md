# Integrating eBPF-Based Runtime Monitoring for Secure Fintech Microservice Architecture

## Problem Statement

Modern fintech platforms use microservices with encrypted communication (TLS/PQC) for transaction security. In this project, ML-KEM and ML-DSA protect confidentiality and integrity, but cryptographic protection alone does not provide runtime visibility into live service interaction behavior.

Traditional monitoring often requires application instrumentation, sidecars, or proxy layers that add overhead and may miss kernel-level network patterns.

## Proposed Solution

An eBPF runtime monitoring layer is added to the existing fintech microservice infrastructure for low-overhead, kernel-level telemetry and anomaly detection without changing microservice code.

## Architecture Extension

1. **Fintech Microservices**
   - Auth Service
   - Account Service
   - Transaction Service
   - Frontend/API consumers

2. **PQC/TLS communication**
   - Service communication remains encrypted.
   - eBPF observes runtime metadata only.

3. **eBPF Monitoring Layer**
   - Attached through Linux kernel probes (`kprobe`/`kretprobe`)
   - Captures connect/close telemetry on TCP flows

4. **Kernel-Level Telemetry Collection**
   - Source/destination IP and ports
   - Process ID and process name
   - Connection latency (used as handshake/flow health proxy)
   - Flow frequency and communication patterns

5. **Security Analysis Engine**
   - Unauthorized service flow detection
   - Lateral movement burst detection
   - High fan-out peer behavior detection
   - Process-to-port mismatch detection (impersonation indicator)

6. **Visualization-ready output**
   - JSON event stream for dashboard/SIEM integration
   - JSONL logs in `logs/ebpf-events.jsonl`

## Implementation in this Repository

- `ebpf/monitor_runtime.py`
  - BCC/eBPF collector
  - Runtime anomaly analyzer
- `ebpf/service_map.json`
  - Service topology, allowed flows, and thresholds
- `start-ebpf-monitor.sh`
  - Root-level launcher
- `ebpf/README.md`
  - Usage and operational details

## Novelty Contribution

- Zero instrumentation monitoring: no Java microservice code changes
- Kernel-level telemetry with low overhead
- Visibility over encrypted microservice communication metadata
- Runtime detection of anomalous service interactions in a PQC-enabled architecture

## One-Line Novelty Statement

"This work introduces an eBPF-based kernel-level monitoring framework for PQC-secured fintech microservice architectures, enabling real-time detection of anomalous service communication without modifying application code."
