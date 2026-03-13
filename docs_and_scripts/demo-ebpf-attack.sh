#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_SCRIPT="${ROOT_DIR}/ebpf/monitor_runtime.py"
ATTACK_SCRIPT="${ROOT_DIR}/ebpf/simulate_unwanted_behavior.py"
CONFIG_FILE="${ROOT_DIR}/ebpf/service_map.attack-demo.json"
LOG_FILE="${ROOT_DIR}/logs/ebpf-attack-demo.jsonl"

mkdir -p "${ROOT_DIR}/logs"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "This demo must run as root for eBPF monitor attachment."
  echo "Try: sudo ./demo-ebpf-attack.sh"
  exit 1
fi

echo "[demo] Starting eBPF monitor in background (attack demo config)"
python3 "${MONITOR_SCRIPT}" \
  --config "${CONFIG_FILE}" \
  --output "${LOG_FILE}" \
  --summary-interval 5 > "${ROOT_DIR}/logs/ebpf-attack-monitor.stdout.log" 2>&1 &
MON_PID=$!

cleanup() {
  if ps -p "${MON_PID}" >/dev/null 2>&1; then
    kill "${MON_PID}" >/dev/null 2>&1 || true
    wait "${MON_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

sleep 2

if ! ps -p "${MON_PID}" >/dev/null 2>&1; then
  echo "[demo] eBPF monitor failed to start. See logs/ebpf-attack-monitor.stdout.log"
  tail -n 40 "${ROOT_DIR}/logs/ebpf-attack-monitor.stdout.log" || true
  exit 1
fi

echo "[demo] Running attack traffic simulation"
python3 "${ATTACK_SCRIPT}" --host 127.0.0.1 --port 19090 --count 50 --delay-ms 5

sleep 3
cleanup

if [[ ! -s "${LOG_FILE}" ]]; then
  echo "[demo] No telemetry output generated in ${LOG_FILE}."
  echo "[demo] Check monitor logs: ${ROOT_DIR}/logs/ebpf-attack-monitor.stdout.log"
  exit 1
fi

echo "[demo] Attack simulation done."
echo "[demo] eBPF JSONL log: ${LOG_FILE}"
echo "[demo] quick check:"
echo "  grep -E 'PROCESS_PORT_MISMATCH|UNAUTHORIZED_FLOW|LATERAL_MOVEMENT_PATTERN' ${LOG_FILE} | head"
