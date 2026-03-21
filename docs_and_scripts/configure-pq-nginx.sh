#!/bin/bash
set -euo pipefail

MODE="${1:---apply}"

if [ "$MODE" != "--apply" ] && [ "$MODE" != "--dry-run" ]; then
    echo "Usage: $0 [--apply|--dry-run]"
    exit 1
fi

TLS_ENV_FILE="${TLS_ENV_FILE:-/home/inba/SIA_BANK/tls-config/nginx-proxy.env}"
TEMPLATE_FILE="${PQ_NGINX_TEMPLATE:-/home/inba/SIA_BANK/tls-config/nginx-pq.conf.template}"

if [ ! -f "$TLS_ENV_FILE" ]; then
    echo "Missing env file: $TLS_ENV_FILE"
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Missing template file: $TEMPLATE_FILE"
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "$TLS_ENV_FILE"
set +a

PQ_NGINX_BIN="${PQ_NGINX_BIN:-/usr/local/nginx-pq/sbin/nginx}"
PQ_NGINX_CONF="${PQ_NGINX_CONF:-/usr/local/nginx-pq/conf/nginx.conf}"
PQ_NGINX_PID_FILE="${PQ_NGINX_PID_FILE:-/usr/local/nginx-pq/logs/nginx.pid}"
PQ_NGINX_HOST="${PQ_NGINX_HOST:-pq-nginx.local}"
PQ_NGINX_PORT="${PQ_NGINX_PORT:-443}"
PQ_NGINX_SERVER_CERT="${PQ_NGINX_SERVER_CERT:-/usr/local/nginx-pq/conf/server-mldsa65.crt}"
PQ_NGINX_SERVER_KEY="${PQ_NGINX_SERVER_KEY:-/usr/local/nginx-pq/conf/server-mldsa65.key}"
PQ_NGINX_CA_CERT="${PQ_NGINX_CA_CERT:-/usr/local/nginx-pq/conf/ca-mldsa87.crt}"
PQ_NGINX_CLIENT_VERIFY="${PQ_NGINX_CLIENT_VERIFY:-optional}"
PQ_NGINX_VERIFY_DEPTH="${PQ_NGINX_VERIFY_DEPTH:-2}"
PQ_NGINX_TLS_GROUPS="${PQ_NGINX_TLS_GROUPS:-X25519MLKEM768}"
PQ_NGINX_SIGNATURE_ALGORITHMS="${PQ_NGINX_SIGNATURE_ALGORITHMS:-ML-DSA-65}"

AUTH_UPSTREAM_HOST="${AUTH_UPSTREAM_HOST:-127.0.0.1}"
ACCOUNT_UPSTREAM_HOST="${ACCOUNT_UPSTREAM_HOST:-127.0.0.1}"
TRANSACTION_UPSTREAM_HOST="${TRANSACTION_UPSTREAM_HOST:-127.0.0.1}"
AUTH_SERVER_PORT="${AUTH_SERVER_PORT:-8083}"
ACCOUNT_SERVER_PORT="${ACCOUNT_SERVER_PORT:-8081}"
TRANSACTION_SERVER_PORT="${TRANSACTION_SERVER_PORT:-8082}"

for required in "$PQ_NGINX_BIN" "$PQ_NGINX_SERVER_CERT" "$PQ_NGINX_SERVER_KEY" "$PQ_NGINX_CA_CERT"; do
    if [ ! -e "$required" ]; then
        echo "Required file not found: $required"
        exit 1
    fi
done

escape_sed() {
    echo "$1" | sed -e 's/[\\&|]/\\&/g'
}

RENDERED="$(mktemp)"
sed \
    -e "s|__AUTH_UPSTREAM_HOST__|$(escape_sed "$AUTH_UPSTREAM_HOST")|g" \
    -e "s|__ACCOUNT_UPSTREAM_HOST__|$(escape_sed "$ACCOUNT_UPSTREAM_HOST")|g" \
    -e "s|__TRANSACTION_UPSTREAM_HOST__|$(escape_sed "$TRANSACTION_UPSTREAM_HOST")|g" \
    -e "s|__AUTH_SERVER_PORT__|$(escape_sed "$AUTH_SERVER_PORT")|g" \
    -e "s|__ACCOUNT_SERVER_PORT__|$(escape_sed "$ACCOUNT_SERVER_PORT")|g" \
    -e "s|__TRANSACTION_SERVER_PORT__|$(escape_sed "$TRANSACTION_SERVER_PORT")|g" \
    -e "s|__PQ_NGINX_HOST__|$(escape_sed "$PQ_NGINX_HOST")|g" \
    -e "s|__PQ_NGINX_PORT__|$(escape_sed "$PQ_NGINX_PORT")|g" \
    -e "s|__PQ_NGINX_SERVER_CERT__|$(escape_sed "$PQ_NGINX_SERVER_CERT")|g" \
    -e "s|__PQ_NGINX_SERVER_KEY__|$(escape_sed "$PQ_NGINX_SERVER_KEY")|g" \
    -e "s|__PQ_NGINX_CA_CERT__|$(escape_sed "$PQ_NGINX_CA_CERT")|g" \
    -e "s|__PQ_NGINX_CLIENT_VERIFY__|$(escape_sed "$PQ_NGINX_CLIENT_VERIFY")|g" \
    -e "s|__PQ_NGINX_VERIFY_DEPTH__|$(escape_sed "$PQ_NGINX_VERIFY_DEPTH")|g" \
    -e "s|__PQ_NGINX_TLS_GROUPS__|$(escape_sed "$PQ_NGINX_TLS_GROUPS")|g" \
    -e "s|__PQ_NGINX_SIGNATURE_ALGORITHMS__|$(escape_sed "$PQ_NGINX_SIGNATURE_ALGORITHMS")|g" \
    "$TEMPLATE_FILE" > "$RENDERED"

if [ "$MODE" = "--dry-run" ]; then
    cat "$RENDERED"
    rm -f "$RENDERED"
    exit 0
fi

install -m 0644 "$RENDERED" "$PQ_NGINX_CONF"
rm -f "$RENDERED"

"$PQ_NGINX_BIN" -t -c "$PQ_NGINX_CONF"

if [ -f "$PQ_NGINX_PID_FILE" ] && kill -0 "$(cat "$PQ_NGINX_PID_FILE")" 2>/dev/null; then
    "$PQ_NGINX_BIN" -s reload
    echo "Reloaded PQ NGINX with config: $PQ_NGINX_CONF"
else
    "$PQ_NGINX_BIN" -c "$PQ_NGINX_CONF"
    echo "Started PQ NGINX with config: $PQ_NGINX_CONF"
fi
