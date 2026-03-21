# PQ NGINX Proxy Setup For SIA_BANK

This repository now supports running your services behind a post-quantum NGINX TLS 1.3 reverse proxy.

## 1) Prerequisites

- OpenSSL 3.5.4+ with ML-DSA / ML-KEM support.
- NGINX compiled against that OpenSSL build (for example `/usr/local/nginx-pq/sbin/nginx`).
- PQ cert/key files copied to `/usr/local/nginx-pq/conf/`:
  - `server-mldsa65.crt`
  - `server-mldsa65.key`
  - `ca-mldsa87.crt`
- Hostname mapped:
  - `127.0.0.1 pq-nginx.local` in `/etc/hosts`

## 2) Proxy Mode Variables

Edit `tls-config/nginx-proxy.env` if paths or hostnames differ.

Important values:
- `PQ_NGINX_BIN`, `PQ_NGINX_CONF`
- `PQ_NGINX_SERVER_CERT`, `PQ_NGINX_SERVER_KEY`, `PQ_NGINX_CA_CERT`
- `PQ_NGINX_TLS_GROUPS` (example: `X25519MLKEM768`)
- `PQ_NGINX_SIGNATURE_ALGORITHMS` (example: `ML-DSA-65`)

## 3) Start Services + Auto-Configure Proxy

```bash
cd /home/inba/SIA_BANK/docs_and_scripts
TLS_MODE=nginx-proxy ./start-services.sh
```

`start-services.sh` now:
- Starts Auth, Account, Transaction services.
- Renders NGINX config from `tls-config/nginx-pq.conf.template`.
- Tests config and starts/reloads PQ NGINX.
- Verifies gateway health at `https://pq-nginx.local/healthz`.

## 4) Frontend Through Gateway

Use the provided profile:

```bash
cd /home/inba/SIA_BANK/bankProject
cp .env.pq-proxy .env
```

This sets:

```env
VITE_API_GATEWAY_URL=https://pq-nginx.local
```

So frontend routes become:
- Auth: `https://pq-nginx.local/auth/api`
- Account: `https://pq-nginx.local/api/...`
- Transaction: `https://pq-nginx.local/api/...`

## 5) Quick Verification

Server cert verification:

```bash
openssl s_client \
  -connect pq-nginx.local:443 \
  -tls1_3 \
  -groups X25519MLKEM768 \
  -CAfile /usr/local/nginx-pq/conf/ca-mldsa87.crt \
  -brief
```

Mutual TLS API call:

```bash
curl -k \
  --cert ~/pq-nginx-demo/client-mldsa65.crt \
  --key ~/pq-nginx-demo/client-mldsa65.key \
  https://pq-nginx.local/auth/api/auth/health
```

## 6) Manual Proxy Reconfigure (Optional)

```bash
sudo -E /home/inba/SIA_BANK/docs_and_scripts/configure-pq-nginx.sh --apply
```
