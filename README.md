# Banking Microservices

A distributed microservices-based banking system built with Spring Boot, featuring proper service separation and inter-service communication using OpenFeign.

## Architecture Overview

This project demonstrates a true microservices architecture with two independently deployable services:

```
┌─────────────────────────────────────────────┐
│           Browser / Client                  │
└────────────┬──────────────┬─────────────────┘
             │              │
    ┌────────▼─────┐   ┌───▼──────────────┐
    │   Account    │   │   Transaction    │
    │   Service    │◄──┤     Service      │
    │   :8080      │   │      :8081       │
    └────────┬─────┘   └───┬──────────────┘
             │             │  (OpenFeign)
    ┌────────▼─────────────▼──────────┐
    │         MySQL Database          │
    │  ┌──────────┐  ┌──────────────┐ │
    │  │account_db│  │transaction_db│ │
    │  └──────────┘  └──────────────┘ │
    └─────────────────────────────────┘
```

### Service Responsibilities

**📦 Account Service (Port 8080)**
- Account management (Create, Read, Update)
- Balance operations (Credit, Debit)
- Account status management
- Direct database access to `account_db`

**📦 Transaction Service (Port 8081)**
- Money transfer coordination
- Transaction logging and history
- Inter-service communication via OpenFeign
- Calls Account Service APIs to perform transfers
- Direct database access to `transaction_db`

## Technology Stack

- **Framework:** Spring Boot 3.0.0
- **Language:** Java 17
- **Build Tool:** Maven 3.9.9
- **Database:** MySQL 8.4+
- **ORM:** Spring Data JPA with Hibernate 6.1.5
- **Service Communication:** OpenFeign 4.0.0
- **Connection Pool:** HikariCP 5.0.1
- **Validation:** Jakarta Bean Validation 3.0.2
- **Utilities:** Lombok 1.18.24

## Project Structure

```
banking-microservices/
├── account-service/
│   ├── src/main/java/com/banking/account/
│   │   ├── AccountServiceApplication.java
│   │   ├── controller/
│   │   │   └── AccountController.java
│   │   ├── service/
│   │   │   ├── AccountService.java
│   │   │   └── AccountServiceImpl.java
│   │   ├── repository/
│   │   │   └── AccountRepository.java
│   │   ├── entity/
│   │   │   ├── Account.java
│   │   │   └── AccountStatus.java (Enum)
│   │   ├── dto/
│   │   │   ├── AccountDTO.java
│   │   │   ├── CreateAccountRequestDTO.java
│   │   │   ├── CreditRequestDTO.java
│   │   │   └── DebitRequestDTO.java
│   │   ├── exception/
│   │   │   ├── AccountNotFoundException.java
│   │   │   ├── AccountInactiveException.java
│   │   │   └── InsufficientBalanceException.java
│   │   └── config/
│   │       └── CorsConfig.java
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   └── schema.sql
│   └── pom.xml
├── transaction-service/
│   ├── src/main/java/com/banking/transaction/
│   │   ├── TransactionServiceApplication.java (@EnableFeignClients)
│   │   ├── controller/
│   │   │   └── HealthController.java
│   │   ├── service/
│   │   │   └── TransactionService.java
│   │   ├── repository/
│   │   │   └── TransactionRepository.java
│   │   ├── entity/
│   │   │   └── Transaction.java
│   │   ├── dto/
│   │   │   ├── TransferRequestDTO.java
│   │   │   ├── CreditRequestDTO.java
│   │   │   └── DebitRequestDTO.java
│   │   ├── client/
│   │   │   └── AccountServiceClient.java (Feign)
│   │   └── config/
│   │       └── CorsConfig.java
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   └── schema.sql
│   └── pom.xml
├── test-ui.html (Browser testing interface)
├── DESIGN_DOCUMENT.md
└── README.md
```

## Getting Started

### Prerequisites

- **Java 17** or higher
- **Maven 3.6+**
- **MySQL 8.4+**
- Linux/Unix environment (or WSL on Windows)

### Installation Steps

1. **Install Java 17**
   ```bash
   sudo apt-get install -y openjdk-17-jdk
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   ```

2. **Install Maven**
   ```bash
   sudo apt-get install -y maven
   ```

3. **Install MySQL**
   ```bash
   sudo apt-get install -y mysql-server
   ```

4. **Create Databases and User**
   ```bash
   sudo mysql -u root -e "
   CREATE DATABASE account_db;
   CREATE DATABASE transaction_db;
   CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'password';
   GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'localhost';
   FLUSH PRIVILEGES;
   "
   ```

5. **Insert Test Data** (Optional)
   ```bash
   mysql -u appuser -ppassword account_db -e "
   INSERT INTO accounts (account_number, customer_id, balance, status, created_at, updated_at) 
   VALUES ('ACC001', 1, 5000.00, 'ACTIVE', NOW(), NOW());
   "
   ```

### Build and Run

1. **Build Both Services**
   ```bash
   cd account-service
   mvn clean install -DskipTests
   
   cd ../transaction-service
   mvn clean install -DskipTests
   ```

2. **Run Account Service** (Terminal 1)
   ```bash
   cd account-service
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   mvn spring-boot:run
   ```
   Service will start on `http://localhost:8080`

3. **Run Transaction Service** (Terminal 2)
   ```bash
   cd transaction-service
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   mvn spring-boot:run
   ```
   Service will start on `http://localhost:8081`

### Testing with Browser UI

1. **Start HTTP Server**
   ```bash
   python3 -m http.server 9000
   ```

2. **Open Browser**
   Navigate to: `http://localhost:9000/test-ui.html`

3. **Test the APIs** using the interactive UI

## API Documentation

### Account Service (Port 8080)

#### Create Account
```http
POST /api/accounts
Content-Type: application/json

{
  "customerId": 100,
  "initialBalance": 1000.00
}

Response: 201 Created
{
  "accountNumber": "ACCF3A2B1C4",
  "customerId": 100,
  "balance": 1000.00,
  "status": "ACTIVE",
  "createdAt": "2026-01-31T10:30:00",
  "updatedAt": "2026-01-31T10:30:00"
}
```

#### Get Account Details
```http
GET /api/accounts/{accountNumber}

Response: 200 OK
{
  "accountNumber": "ACC001",
  "customerId": 1,
  "balance": 5000.00,
  "status": "ACTIVE",
  "createdAt": "2026-01-31T10:30:00",
  "updatedAt": "2026-01-31T10:30:00"
}
```

#### Credit Account (Deposit)
```http
PUT /api/accounts/{accountNumber}/credit
Content-Type: application/json

{
  "senderAccount": "SYSTEM",
  "amount": 500.00,
  "description": "Salary deposit"
}

Response: 200 OK
"Credit successful"
```

#### Debit Account (Withdrawal)
```http
PUT /api/accounts/{accountNumber}/debit
Content-Type: application/json

{
  "senderAccount": "ACC001",
  "amount": 100.00,
  "description": "ATM withdrawal"
}

Response: 200 OK
"Debit successful"
```

### Transaction Service (Port 8081)

#### Transfer Money Between Accounts
```http
POST /api/transactions/transfer
Content-Type: application/json

{
  "fromAccountNumber": "ACC001",
  "toAccountNumber": "ACCF3A2B1C4",
  "amount": 250.00,
  "description": "Payment"
}

Response: 200 OK
"Transfer successful. Transaction ID: TXN1A2B3C4D5E6F"
```

**How Transfer Works:**
1. Transaction Service receives transfer request
2. Uses OpenFeign to call Account Service `/debit` endpoint
3. Uses OpenFeign to call Account Service `/credit` endpoint
4. Logs transaction in `transaction_db`
5. Returns success/failure response

#### Health Check
```http
GET /

Response: 200 OK
{
  "service": "Transaction Service",
  "status": "UP",
  "port": "8081"
}
```

## Database Schema

### Account Service Database (account_db)

**Table: accounts**
```sql
CREATE TABLE accounts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  account_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id BIGINT NOT NULL,
  balance DECIMAL(19,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Transaction Service Database (transaction_db)

**Table: transactions**
```sql
CREATE TABLE transactions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  transaction_id VARCHAR(50) UNIQUE NOT NULL,
  from_account_number VARCHAR(50) NOT NULL,
  to_account_number VARCHAR(50) NOT NULL,
  amount DECIMAL(19,2) NOT NULL,
  description TEXT,
  status VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL
);
```

## Configuration

### Account Service (application.yml)
```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/account_db
    username: appuser
    password: password
  jpa:
    hibernate:
      ddl-auto: update
```

### Transaction Service (application.yml)
```yaml
server:
  port: 8081

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/transaction_db
    username: appuser
    password: password
  application:
    name: transaction-service
  jpa:
    hibernate:
      ddl-auto: update
```

## Key Features

✅ **Microservices Architecture** - Independently deployable services  
✅ **Service Communication** - OpenFeign for inter-service calls  
✅ **Database Per Service** - Separate databases for data isolation  
✅ **CORS Enabled** - Browser-based testing support  
✅ **Transaction Logging** - All transfers logged in transaction database  
✅ **Validation** - Jakarta Bean Validation on all inputs  
✅ **Exception Handling** - Proper error responses  
✅ **Auto-generated IDs** - UUID-based account and transaction IDs

## Testing Workflow

1. **Create Account 1**
   - POST to `/api/accounts` with customerId=100, balance=1000
   - Save returned account number (e.g., ACCF3A2B1C4)

2. **Create Account 2**
   - POST to `/api/accounts` with customerId=200, balance=2000
   - Save returned account number (e.g., ACCABCD1234)

3. **Transfer Money**
   - POST to `/api/transactions/transfer`
   - From: ACCF3A2B1C4, To: ACCABCD1234, Amount: 250

4. **Verify Balances**
   - GET `/api/accounts/ACCF3A2B1C4` → Balance should be 750
   - GET `/api/accounts/ACCABCD1234` → Balance should be 2250

## Troubleshooting

**Services Not Starting:**
```bash
# Check if JAVA_HOME is set
echo $JAVA_HOME

# Check if ports are available
ss -tuln | grep -E "8080|8081"

# Check service logs
tail -f /tmp/account-service.log
tail -f /tmp/transaction-service.log
```

**Database Connection Issues:**
```bash
# Test MySQL connection
mysql -u appuser -ppassword account_db -e "SELECT 1;"

# Verify databases exist
mysql -u appuser -ppassword -e "SHOW DATABASES;"
```

**CORS Errors in Browser:**
- Ensure both services have CorsConfig.java
- Restart services after adding CORS configuration

## Future Enhancements

- [ ] API Gateway (Spring Cloud Gateway)
- [ ] Service Discovery (Eureka)
- [ ] Circuit Breaker (Resilience4j)
- [ ] Distributed Tracing (Zipkin)
- [ ] Caching Layer (Redis)
- [ ] Message Queue (RabbitMQ/Kafka)
- [ ] Authentication & Authorization (JWT)
- [ ] Docker & Kubernetes Deployment

## Documentation

- **Design Document:** See [DESIGN_DOCUMENT.md](DESIGN_DOCUMENT.md) for comprehensive architecture details
- **Test UI:** Open `test-ui.html` in browser for interactive API testing

## License

MIT License