# Banking Microservices - Run Guide

## Prerequisites

- Java 17 or higher
- MySQL database running on localhost:3306
- Databases created: `account_db` and `transaction_db`
- Services already built (JAR files exist in target/ directories)

## Running the Services

### Option 1: Run in Foreground (Recommended for Development)

**Terminal 1 - Account Service:**
```bash
cd "/home/inba/Fintech Microservice/banking-microservices/account-service"
java -jar target/account-service-1.0.0.jar
```

**Terminal 2 - Transaction Service:**
```bash
cd "/home/inba/Fintech Microservice/banking-microservices/transaction-service"
java -jar target/transaction-service-1.0.0.jar
```

### Option 2: Run in Background

```bash
cd "/home/inba/Fintech Microservice/banking-microservices"

# Create logs directory if it doesn't exist
mkdir -p logs

# Start Account Service
java -jar account-service/target/account-service-1.0.0.jar > logs/account-service.log 2>&1 &
echo "Account Service started with PID: $!"

# Wait for Account Service to start
sleep 5

# Start Transaction Service
java -jar transaction-service/target/transaction-service-1.0.0.jar > logs/transaction-service.log 2>&1 &
echo "Transaction Service started with PID: $!"

# View logs
tail -f logs/account-service.log
# or
tail -f logs/transaction-service.log
```

### Check Running Services

```bash
# Check if services are running
ps aux | grep -E "(account-service|transaction-service)" | grep -v grep

# Check ports
ss -tulpn | grep -E "(8443|8082)"
```

### Stop Services

```bash
# If running in foreground: Press Ctrl+C

# If running in background:
pkill -f account-service-1.0.0.jar
pkill -f transaction-service-1.0.0.jar

# Or find and kill specific PIDs:
ps aux | grep account-service-1.0.0.jar | grep -v grep | awk '{print $2}' | xargs kill
ps aux | grep transaction-service-1.0.0.jar | grep -v grep | awk '{print $2}' | xargs kill
```

## Service Endpoints

### Account Service
- **URL**: `https://localhost:8443`
- **Endpoints**:
  - GET `/api/accounts` - Get all accounts
  - POST `/api/accounts` - Create account
  - GET `/api/accounts/{accountNumber}` - Get account by number
  - PUT `/api/accounts/{accountNumber}/debit` - Debit account
  - PUT `/api/accounts/{accountNumber}/credit` - Credit account

### Transaction Service
- **URL**: `https://localhost:8082`
- **Endpoints**:
  - GET `/health` - Health check
  - POST `/api/transactions/transfer` - Transfer between accounts

## Testing with mTLS

### Test Account Service (requires client certificate)

```bash
cd "/home/inba/Fintech Microservice/banking-microservices"

# Get all accounts
curl -k --cert certs/transaction-service.crt \
     --key certs/transaction-service.key \
     https://localhost:8443/api/accounts

# Create an account
curl -k --cert certs/transaction-service.crt \
     --key certs/transaction-service.key \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"customerId":"CUST001","balance":1000.00}' \
     https://localhost:8443/api/accounts
```

### Test Transaction Service

```bash
# Health check
curl -k --cert certs/account-service.crt \
     --key certs/account-service.key \
     https://localhost:8082/health

# Transfer between accounts
curl -k --cert certs/account-service.crt \
     --key certs/account-service.key \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{
       "fromAccountNumber": "ACC001",
       "toAccountNumber": "ACC002",
       "amount": 100.00
     }' \
     https://localhost:8082/api/transactions/transfer
```

### Test without client certificate (should fail)

```bash
# This should fail with "certificate required" error
curl -k https://localhost:8443/api/accounts
```

## Building from Source

If you need to rebuild the services:

```bash
cd "/home/inba/Fintech Microservice/banking-microservices"

# Build both services
mvn clean package -DskipTests

# Or build individually
cd account-service && mvn clean package -DskipTests
cd ../transaction-service && mvn clean package -DskipTests
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using the port
sudo lsof -i :8443
sudo lsof -i :8082

# Kill the process
kill <PID>
```

### Database Connection Issues

Verify MySQL is running and databases exist:
```bash
mysql -u appuser -p -e "SHOW DATABASES;"
```

### Certificate Issues

Verify certificates exist:
```bash
ls -lh certs/*.{crt,key,p12}
```

### View Logs

```bash
# If running in background
tail -f logs/account-service.log
tail -f logs/transaction-service.log

# Check for errors
grep -i error logs/account-service.log
grep -i error logs/transaction-service.log
```

## Security Features

- **mTLS (Mutual TLS)**: Both services require client certificates for authentication
- **RSA 2048-bit**: Classical RSA encryption for certificates
- **Certificate Authority**: Custom CA for signing service certificates
- **SSL/TLS**: All communication encrypted with HTTPS

## Architecture

```
┌─────────────────────┐                 ┌──────────────────────┐
│  Transaction        │    mTLS         │  Account Service     │
│  Service            │◄───────────────►│  (8443)              │
│  (8082)             │  Feign Client   │                      │
└─────────────────────┘                 └──────────────────────┘
         │                                        │
         │                                        │
         ▼                                        ▼
┌─────────────────────┐                 ┌──────────────────────┐
│  transaction_db     │                 │  account_db          │
│  (MySQL)            │                 │  (MySQL)             │
└─────────────────────┘                 └──────────────────────┘
```

## Notes

- Both services enforce mutual TLS authentication
- Transaction Service communicates with Account Service using mTLS
- All certificates are stored in `certs/` directory
- Keystores are in PKCS12 format
- Default password for all keystores: `changeit`
