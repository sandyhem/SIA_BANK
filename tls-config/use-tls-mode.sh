#!/bin/bash
set -e

MODE="${1:-}"
if [ -z "$MODE" ]; then
    echo "Usage: source tls-config/use-tls-mode.sh <direct-tls|nginx-proxy>"
    return 1 2>/dev/null || exit 1
fi

case "$MODE" in
    direct-tls)
        ENV_FILE="/home/inba/SIA_BANK/tls-config/direct-tls.env"
        ;;
    nginx-proxy)
        ENV_FILE="/home/inba/SIA_BANK/tls-config/nginx-proxy.env"
        ;;
    *)
        echo "Unknown mode: $MODE"
        return 1 2>/dev/null || exit 1
        ;;
esac

set -a
source "$ENV_FILE"
set +a

echo "Loaded TLS mode: $MODE"
