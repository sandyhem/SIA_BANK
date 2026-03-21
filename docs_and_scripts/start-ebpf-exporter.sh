#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INPUT_FILE="${ROOT_DIR}/logs/ebpf-attack-demo.jsonl"
EXPORTER_SCRIPT="${ROOT_DIR}/ebpf/export_prometheus_metrics.py"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required"
  exit 1
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "Input log not found: ${INPUT_FILE}"
  echo "Run eBPF monitor/demo first to generate JSONL logs."
  exit 1
fi

python3 "${EXPORTER_SCRIPT}" \
  --input "${INPUT_FILE}" \
  --host 0.0.0.0 \
  --port 9110
