# Banking Microservices - Design Document

## 1. Project Overview

**Project Name:** Banking Microservices with React Frontend  
**Version:** 2.0.0  
**Date:** February 13, 2026  
**Purpose:** A distributed microservices architecture for managing bank accounts, transactions, and user authentication with a modern React frontend.

### Key Objectives
- Provide secure user authentication and authorization with JWT
- Provide scalable account management functionality
- Enable transaction processing with financial operations
- Implement service-to-service communication using OpenFeign
- Ensure data consistency and reliability
- Support independent scaling of services
- Modern React-based user interface with real-time data

---

## 2. Architecture Overview

### 2.1 System Architecture
```
┌─────────────────────────────────────────────────────────┐
│              React Frontend (Vite)                       │
│              Port: 5174                                  │
│              - Authentication UI                         │
│              - Account Management                        │
│              - Transfers & Transactions                  │
└────────────────┬────────────────────────────────────────┘
                 │ HTTP/REST + JWT
        ┌────────┴────────┬────────────────┐
        │                 │                 │
   ┌────▼────┐       ┌───▼─────┐      ┌───▼─────┐
   │  Auth    │       │ Account  │      │Transaction│
   │ Service  │       │ Service  │      │ Service   │
   │ :8083    │       │ :8081    │      │ :8082     │
   └────┬────┘       └───┬─────┘      └───┬─────┘
        │                │                 │
        │                │ (OpenFeign + JWT Forwarding)│
        │                └────────┬────────┘
        │                         │
        │                         │
        └───────┬─────────────────┘
                │
        ┌───────▼────────┐
        │  MySQL 8.4     │
        ├────────────────┤
        │ auth_db        │
        │ account_db     │
        │ transaction_db │
        └────────────────┘
```

### 2.2 Services
1. **Auth Service** - User authentication, registration, and JWT token management
2. **Account Service** - Bank account management and operations
3. **Transaction Service** - Financial transactions and transfers
4. **Frontend Application** - React-based user interface with Vite

### 2.3 Communication
- **Frontend to Backend:** HTTP/REST with JWT Bearer tokens
- **Internal Service Communication:** OpenFeign with JWT forwarding via FeignClientInterceptor
- **Data Persistence:** Spring Data JPA with Hibernate ORM
- **Database:** MySQL 8.4
- **Authentication:** JWT (HS256) with 24-hour token expiration

---

## 3. Service Specifications

### 3.1 Auth Service

**Port:** 8083  
**Database:** auth_db

#### Responsibilities
- User registration and account creation
- User authentication and login
- JWT token generation and validation
- Password encryption (BCrypt)
- User management

#### Key Components

##### Entities
```
User
├── id (Long) - Primary Key
├── username (String) - Unique username
├── password (String) - BCrypt hashed password
├── email (String) - User email
├── firstName (String) - User's first name
├── lastName (String) - User's last name
├── phone (String) - Phone number
├── customerId (String) - Unique QB2026-XXXX identifier
├── kycStatus (String) - KYC verification status (PENDING, VERIFIED, REJECTED)
├── createdAt (LocalDateTime) - Registration timestamp
└── updatedAt (LocalDateTime) - Last update timestamp
```

##### DTOs
```
RegisterRequestDTO
├── username
├── password
├── email
├── firstName
├── lastName
└── phone

LoginRequestDTO
├── username
└── password

AuthResponseDTO
├── token (JWT)
├── userId
├── username
├── customerId
├── firstName
├── lastName
├── email
└── phone
```

##### Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | /api/auth/register | Register new user | No |
| POST | /api/auth/login | User login with JWT | No |
| GET | /api/auth/me | Get current user info | Yes |

### 3.2 Account Service

**Port:** 8081  
**Database:** account_db

#### Responsibilities
- Account creation and management
- Account status tracking (ACTIVE, INACTIVE, SUSPENDED, CLOSED)
- Credit operations (deposit funds)
- Debit operations (withdraw funds)
- Account inquiry and retrieval by customer

#### Key Components

##### Entities
```
Account
├── id (Long) - Primary Key
├── accountNumber (String) - Unique identifier
├── accountName (String) - Display name for account
├── accountType (String) - CHECKING, SAVINGS, FIXED, INVESTMENT
├── customerId (Long) - Reference to customer
├── balance (BigDecimal) - Current balance
├── status (AccountStatus) - Enum: ACTIVE, INACTIVE, SUSPENDED, CLOSED
├── createdAt (LocalDateTime) - Creation timestamp
└── updatedAt (LocalDateTime) - Last modification timestamp
```

##### DTOs
```
AccountDTO - Response model with account details
├── accountNumber
├── accountName
├── accountType
├── customerId
├── balance
├── status
├── createdAt
└── updatedAt

CreateAccountRequestDTO - Request to create new account
├── customerId
├── accountName
├── accountType
└── initialBalance

CreditRequestDTO - Request to credit account
├── senderAccount
├── amount (BigDecimal)
└── description

DebitRequestDTO - Request to debit account
├── senderAccount
├── amount (BigDecimal)
└── description
```

##### Exceptions
- `AccountNotFoundException` - Account does not exist
- `AccountInactiveException` - Account is not active for operations
- `InsufficientBalanceException` - Insufficient funds for debit operation

#### API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/accounts` | Create new account | Yes |
| GET | `/api/accounts/{accountNumber}` | Retrieve account details | Yes |
| GET | `/api/accounts/customer/{customerId}` | Get all accounts for customer | Yes |
| PUT | `/api/accounts/{accountNumber}/credit` | Credit funds to account | Yes |
| PUT | `/api/accounts/{accountNumber}/debit` | Debit funds from account | Yes |

---

### 3.3 Transaction Service

**Port:** 8082  
**Database:** transaction_db

#### Responsibilities
- Transaction logging and tracking
- Inter-account transfers (internal and external)
- Transaction history management
- Transaction status monitoring
- Balance updates via Account Service integration

#### Key Components

##### Entities
```
Transaction
├── id (Long) - Primary Key
├── transactionId (String) - Unique transaction identifier
├── accountNumber (String) - Source/Target account
├── amount (BigDecimal) - Transaction amount
├── transactionType (TransactionType) - CREDIT or DEBIT
├── transactionDate (LocalDateTime) - When transaction occurred
├── description (String) - Transaction description
├── status (String) - Transaction status (PENDING, COMPLETED, FAILED)
├── referenceNumber (String) - External reference
├── balanceBefore (BigDecimal) - Balance before transaction
├── balanceAfter (BigDecimal) - Balance after transaction
└── category (String) - Transaction category
```

##### DTOs
```
TransactionDTO - Response model
├── transactionId
├── accountNumber
├── amount
├── transactionType
├── transactionDate
├── description
├── status
├── referenceNumber
├── balanceBefore
└── balanceAfter

TransferRequestDTO - Request for money transfer
├── fromAccount
├── toAccount
├── amount
└── description
```

#### API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/transactions/transfer` | Transfer funds between accounts | Yes |
| GET | `/api/transactions/account/{accountNumber}` | Get transaction history | Yes |
| GET | `/api/transactions/{transactionId}` | Get transaction details | Yes |

---

## 4. Database Design

### 4.1 Auth Service Database (auth_db)

```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(20),
  customer_id VARCHAR(20) UNIQUE NOT NULL,
  kyc_status VARCHAR(20) DEFAULT 'PENDING',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_username (username),
  INDEX idx_email (email),
  INDEX idx_customer_id (customer_id)
);
```

### 4.2 Account Service Database (account_db)

```sql
CREATE TABLE accounts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  account_number VARCHAR(50) UNIQUE NOT NULL,
  account_name VARCHAR(100),
  account_type VARCHAR(50) NOT NULL,
  customer_id BIGINT NOT NULL,
  balance DECIMAL(19,2) NOT NULL DEFAULT 0.00,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_account_number (account_number),
  INDEX idx_customer_id (customer_id)
);
```

### 4.3 Transaction Service Database (transaction_db)

```sql
CREATE TABLE transactions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  transaction_id VARCHAR(100) UNIQUE NOT NULL,
  account_number VARCHAR(50) NOT NULL,
  amount DECIMAL(19,2) NOT NULL,
  transaction_type VARCHAR(20) NOT NULL,
  transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  description VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
  reference_number VARCHAR(100),
  balance_before DECIMAL(19,2),
  balance_after DECIMAL(19,2),
  category VARCHAR(50),
  INDEX idx_transaction_id (transaction_id),
  INDEX idx_account_number (account_number),
  INDEX idx_transaction_date (transaction_date)
);
```
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  INDEX idx_account_number (account_number),
  INDEX idx_customer_id (customer_id)
);
```

### 4.2 Transaction Service Database (transaction_db)

Currently minimal schema. Can be extended with:

```sql
-- Future tables
CREATE TABLE transactions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  transaction_id VARCHAR(50) UNIQUE NOT NULL,
  account_number VARCHAR(50) NOT NULL,
  type VARCHAR(20) NOT NULL, -- CREDIT, DEBIT, TRANSFER
  amount DECIMAL(19,2) NOT NULL,
  description TEXT,
  status VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  INDEX idx_transaction_id (transaction_id),
  INDEX idx_account_number (account_number)
);
```

---

## 5. Frontend Architecture

### 5.1 Overview
**Framework:** React 18 with Vite  
**Port:** 5174 (Development)  
**Build Tool:** Vite 6.0.11  
**Package Manager:** npm

### 5.2 Key Features
- Modern React application with functional components and hooks
- JWT-based authentication with session persistence
- Protected routes with authentication guards
- Real-time account and transaction data
- Responsive design with Tailwind CSS
- Toast notifications for user feedback

### 5.3 Project Structure
```
bankProject/
├── src/
│   ├── components/
│   │   ├── QuantumLayout.jsx - Main layout wrapper
│   │   ├── ProtectedRoute.jsx - Route authentication guard
│   │   ├── CreateAccountModal.jsx - Account creation modal
│   │   └── Toast.jsx - Notification component
│   ├── pages/
│   │   ├── Login.jsx - Login page
│   │   ├── Register.jsx - User registration
│   │   ├── QuantumBankingDashboard.jsx - Main dashboard
│   │   ├── Transfers.jsx - Money transfer page
│   │   └── Transactions.jsx - Transaction history
│   ├── services/
│   │   ├── api.js - Axios configuration with JWT interceptor
│   │   ├── authService.js - Authentication API calls
│   │   ├── accountService.js - Account API calls
│   │   └── transactionService.js - Transaction API calls
│   ├── context/
│   │   └── AuthContext.jsx - Global authentication state
│   ├── hooks/
│   │   └── useData.js - Custom hooks for data fetching
│   └── App.jsx - Route configuration
└── .env - Environment variables (API endpoints)
```

### 5.4 Key Components

#### Authentication Flow
1. User logs in via `/login` page
2. AuthService sends credentials to Auth Service (`/api/auth/login`)
3. JWT token received and stored in localStorage
4. AuthContext provides global auth state
5. Protected routes verify token before rendering
6. Axios interceptor adds JWT to all API requests
7. 401 responses trigger automatic logout

#### API Integration
```javascript
// API Base Configuration (.env)
VITE_API_BASE_URL=http://localhost
VITE_AUTH_SERVICE_PORT=8083
VITE_ACCOUNT_SERVICE_PORT=8081
VITE_TRANSACTION_SERVICE_PORT=8082

// Services communicate with respective backend services
authService → http://localhost:8083/api/auth
accountService → http://localhost:8081/api/accounts
transactionService → http://localhost:8082/api/transactions
```

#### State Management
- **AuthContext:** Global user authentication state, logout function
- **Local State:** Component-level state with useState
- **Data Fetching:** Custom `useAccounts` hook with loading/error/refetch
- **Session Persistence:** localStorage for JWT token storage

#### UI/UX Features
- **CreateAccountModal:** Modal form for creating new accounts
- **Toast Notifications:** Success/Error feedback (auto-dismiss after 5s)
- **Real-time Refresh:** Manual refresh buttons and auto-refresh after operations
- **Loading States:** Visual feedback during API calls
- **Error Handling:** User-friendly error messages

### 5.5 Pages and Features

#### Login Page (`/login`)
- Username/password authentication
- JWT token retrieval
- Session persistence
- Redirect to dashboard on success

#### Register Page (`/register`)
- User registration form (username, password, email, firstName, lastName, phone)
- Auto-generated customerId (QB2026-XXXX)
- KYC status initialization
- Automatic login after registration

#### Dashboard (`/dashboard`)
- Display all user accounts
- Account creation via modal
- Quick account overview (balance, type, status)
- Refresh account data
- Navigation to transfers/transactions

#### Transfers Page (`/transfers`)
- Internal transfers (between own accounts)
- External transfers (to other accounts)
- Real account selection from API
- Form validation
- Toast notifications
- Auto-refresh after successful transfer

#### Transactions Page (`/transactions`)
- Account selection dropdown
- Transaction history display
- Search and filter by type/category
- Transaction details view
- Real-time data from Transaction Service

---

## 6. Technology Stack

### Backend
- **Framework:** Spring Boot 3.0.0
- **Language:** Java 17
- **Build Tool:** Maven 3.9.9
- **JPA/ORM:** Spring Data JPA with Hibernate 6.1.5

### Frontend
- **Framework:** React 18
- **Build Tool:** Vite 6.0.11
- **HTTP Client:** Axios 1.7.9
- **Routing:** React Router DOM 7.1.3
- **Icons:** Lucide React 0.469.0

### Database
- **Primary Database:** MySQL 8.4
- **Connection Pool:** HikariCP 5.0.1
- **JDBC Driver:** MySQL Connector/J 8.0.31

### Authentication & Security
- **JWT:** HS256 algorithm with 24-hour expiration
- **Password Encryption:** BCrypt
- **Token Storage:** localStorage (Frontend)
- **Inter-service Auth:** JWT forwarding via FeignClientInterceptor

### Inter-Service Communication
- **HTTP Client:** OpenFeign 4.0.0
- **Service Discovery:** Spring Cloud 2022.0.0

### Utilities
- **Lombok:** 1.18.24 (Reduce boilerplate code)
- **Validation:** Jakarta Validation API 3.0.2
- **Logging:** Logback 1.4.5

### Testing (Optional)
- **Framework:** JUnit 5.9.1
- **Mocking:** Mockito 4.8.1
- **Assertions:** AssertJ 3.23.1

---

## 6. Configuration

### 6.1 Account Service Configuration

**File:** `account-service/src/main/resources/application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/account_db
    username: appuser
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true
  server:
    port: 8080

logging:
  level:
    org.springframework: INFO
    com.banking: DEBUG
```

### 6.2 Transaction Service Configuration

**File:** `transaction-service/src/main/resources/application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/transaction_db
    username: appuser
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true
  application:
    name: transaction-service

server:
  port: 8081

logging:
  level:
    com.banking.transaction: DEBUG
```

---

## 7. Setup and Installation

### 7.1 Prerequisites
- Java 17 JDK
- Maven 3.6+
- MySQL 8.4+
- Linux/Unix environment (or WSL on Windows)

### 7.2 Installation Steps

1. **Install Java 17**
   ```bash
   sudo apt-get install -y openjdk-17-jdk
   ```

2. **Install Maven**
   ```bash
   sudo apt-get install -y maven
   ```

3. **Install MySQL**
   ```bash
   sudo apt-get install -y mysql-server
   ```

4. **Set JAVA_HOME**
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   export PATH=$JAVA_HOME/bin:$PATH
   ```

5. **Create MySQL Databases**
   ```bash
   sudo mysql -u root -e "
   CREATE DATABASE account_db;
   CREATE DATABASE transaction_db;
   CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'password';
   GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'localhost';
   FLUSH PRIVILEGES;
   "
   ```

6. **Build Services**
   ```bash
   cd auth && mvn clean install -DskipTests
   cd ../account-service && mvn clean install -DskipTests
   cd ../transaction-service && mvn clean install -DskipTests
   ```

### 7.3 Running Services

**Auth Service** (Terminal 1)
```bash
cd auth
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
mvn spring-boot:run
# Running on port 8083
```

**Account Service** (Terminal 2)
```bash
cd account-service
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
mvn spring-boot:run
# Running on port 8081
```

**Transaction Service** (Terminal 3)
```bash
cd transaction-service
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
mvn spring-boot:run
# Running on port 8082
```

**Frontend Application** (Terminal 4)
```bash
cd bankProject
npm install  # First time only
npm run dev
# Running on http://localhost:5174
```

### 7.4 Verification

**Check Services:**
```bash
# Auth Service
curl http://localhost:8083/actuator/health

# Account Service
curl http://localhost:8081/actuator/health

# Transaction Service
curl http://localhost:8082/actuator/health

# Frontend
# Open browser: http://localhost:5174
```

**Test JWT Authentication:**
```bash
# Register new user
curl -X POST http://localhost:8083/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123",
    "email": "test@example.com",
    "firstName": "Test",
    "lastName": "User",
    "phone": "1234567890"
  }'

# Login
curl -X POST http://localhost:8083/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'
```

---

## 8. API Documentation

### 8.1 Account Service APIs

#### Get Account Details
```
GET /api/accounts/{accountNumber}
Content-Type: application/json

Response (200):
{
  "accountNumber": "ACC001",
  "customerId": 1,
  "balance": 5000.00,
  "status": "ACTIVE",
  "createdAt": "2026-01-31T10:30:00",
  "updatedAt": "2026-01-31T10:30:00"
}

Response (404):
{
  "timestamp": "2026-01-31T10:31:00",
  "status": 404,
  "error": "Not Found",
  "message": "Account not found: ACC001"
}
```

#### Credit Account (Deposit)
```
PUT /api/accounts/{accountNumber}/credit
Content-Type: application/json

Request Body:
{
  "senderAccount": "ACC002",
  "amount": 1000.50,
  "description": "Salary deposit"
}

Response (200):
"Credit successful"

Response (400):
{
  "timestamp": "2026-01-31T10:32:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Account is not active"
}
```

#### Debit Account (Withdrawal)
```
PUT /api/accounts/{accountNumber}/debit
Content-Type: application/json

Request Body:
{
  "senderAccount": "ACC001",
  "amount": 500.00,
  "description": "ATM withdrawal"
}

Response (200):
"Debit successful"

Response (400):
{
  "timestamp": "2026-01-31T10:33:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Insufficient balance"
}
```

---

## 9. Error Handling

### 9.1 Exception Hierarchy
```
RuntimeException
├── AccountNotFoundException
├── AccountInactiveException
└── InsufficientBalanceException
```

### 9.2 HTTP Status Codes
| Status | Scenario |
|--------|----------|
| 200 | Successful operation |
| 400 | Invalid request (insufficient balance, inactive account) |
| 404 | Account not found |
| 500 | Internal server error |

---

## 10. Transaction Flow Example

### Credit Operation Flow
```
1. Client sends PUT request to /api/accounts/ACC001/credit
2. Controller receives CreditRequestDTO
3. Service validates:
   - Account exists
   - Account status is ACTIVE
4. Service adds amount to balance
5. Repository saves updated account
6. Response sent: "Credit successful"
7. Hibernate persists changes to database
```

### Debit Operation Flow
```
1. Client sends PUT request to /api/accounts/ACC001/debit
2. Controller receives DebitRequestDTO
3. Service validates:
   - Account exists
   - Account status is ACTIVE
   - Balance >= debit amount
4. Service subtracts amount from balance
5. Repository saves updated account
6. Response sent: "Debit successful"
7. Hibernate persists changes to database
```

---

## 11. Security Considerations

### Current Implementation
- Basic authentication via database credentials
- Input validation using Jakarta Bean Validation
- SQL injection prevention via parameterized queries (JPA)

### Future Enhancements
- JWT-based authentication
- Role-based access control (RBAC)
- OAuth2 integration
- API rate limiting
- Request/Response encryption (HTTPS)
- Audit logging
- Data encryption at rest

---

## 12. Performance Considerations

### Current Optimizations
- Connection pooling (HikariCP)
- Database indexing on frequently queried columns
- JPA lazy loading for relationships
- Transaction management via Spring @Transactional

### Recommended Future Improvements
- Caching layer (Redis)
- Database query optimization
- Asynchronous processing for heavy operations
- Circuit breaker pattern for inter-service calls
- Load balancing

---

## 13. Testing Strategy

### Unit Testing
- Service layer testing with Mockito
- Repository testing with embedded H2 database
- Controller testing with MockMvc

### Integration Testing
- End-to-end API testing
- Database integration testing
- Service-to-service communication testing

### Test Example
```java
@SpringBootTest
class AccountServiceTest {
    @Autowired
    private AccountService accountService;
    
    @Test
    void testCreditAccount() {
        // Arrange
        Account account = new Account();
        account.setAccountNumber("ACC001");
        account.setBalance(new BigDecimal("1000"));
        account.setStatus(AccountStatus.ACTIVE);
        
        // Act
        CreditRequestDTO creditRequest = new CreditRequestDTO();
        creditRequest.setAmount(new BigDecimal("500"));
        accountService.creditAccount("ACC001", creditRequest);
        
        // Assert
        assertEquals(new BigDecimal("1500"), account.getBalance());
    }
}
```

---

## 14. Deployment Architecture

### Development Environment
- Local MySQL instance
- Local application servers
- Maven for building

### Production Environment (Recommended)
```
┌─────────────────────────────────────┐
│        Docker Container Registry    │
│  (Account Service, Transaction Svc) │
└────────────────┬────────────────────┘
                 │
         ┌───────▼─────────┐
         │  Kubernetes     │
         │  Orchestration  │
         └───────┬─────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼──┐    ┌───▼──┐    ┌──▼────┐
│ Pod1 │    │ Pod2 │    │ Pod3  │
│ Svc1 │    │ Svc2 │    │ Svc1  │
└───┬──┘    └───┬──┘    └───┬───┘
    └────────────┼────────────┘
                 │
         ┌───────▼────────┐
         │ Cloud MySQL    │
         │ (Managed)      │
         └────────────────┘
```

### Docker Support (Future)
```dockerfile
FROM openjdk:17-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Kubernetes Deployment (Future)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: account-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: account-service
  template:
    metadata:
      labels:
        app: account-service
    spec:
      containers:
      - name: account-service
        image: banking/account-service:1.0.0
        ports:
        - containerPort: 8080
```

---

## 15. Monitoring and Logging

### Current Implementation
- Logback for logging
- SLF4J for log abstraction
- Application-level logging

### Recommended Future Monitoring
- **Metrics:** Micrometer + Prometheus
- **Tracing:** Spring Cloud Sleuth + Zipkin
- **Logging:** ELK Stack (Elasticsearch, Logstash, Kibana)
- **Health Checks:** Spring Boot Actuator
- **Alerting:** PagerDuty/Opsgenie

### Logging Levels
```yaml
ROOT: INFO
org.springframework: INFO
com.banking: DEBUG
org.hibernate: DEBUG
```

---

## 16. Future Enhancements

### Phase 2
- [ ] API Gateway implementation
- [ ] Service discovery (Eureka/Consul)
- [ ] Configuration server
- [ ] Distributed tracing
- [ ] Caching layer (Redis)

### Phase 3
- [ ] Payment gateway integration
- [ ] Mobile app API
- [ ] Admin dashboard
- [ ] Advanced reporting
- [ ] Notification service

### Phase 4
- [ ] Machine learning for fraud detection
- [ ] Advanced analytics
- [ ] Multi-currency support
- [ ] International transfers
- [ ] Blockchain integration for audit trail

---

## 17. Project Structure

```
banking-microservices/
├── README.md
├── account-service/
│   ├── pom.xml
│   ├── src/main/
│   │   ├── java/com/banking/account/
│   │   │   ├── AccountServiceApplication.java
│   │   │   ├── controller/
│   │   │   │   └── AccountController.java
│   │   │   ├── service/
│   │   │   │   ├── AccountService.java (Interface)
│   │   │   │   └── AccountServiceImpl.java (Implementation)
│   │   │   ├── repository/
│   │   │   │   └── AccountRepository.java
│   │   │   ├── entity/
│   │   │   │   ├── Account.java
│   │   │   │   └── AccountStatus.java (Enum)
│   │   │   ├── dto/
│   │   │   │   ├── AccountDTO.java
│   │   │   │   ├── CreditRequestDTO.java
│   │   │   │   └── DebitRequestDTO.java
│   │   │   └── exception/
│   │   │       ├── AccountNotFoundException.java
│   │   │       ├── AccountInactiveException.java
│   │   │       └── InsufficientBalanceException.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── schema.sql
│   └── target/
│
└── transaction-service/
    ├── pom.xml
    ├── src/main/
    │   ├── java/com/banking/transaction/
    │   │   └── TransactionServiceApplication.java
    │   └── resources/
    │       ├── application.yml
    │       └── schema.sql
    └── target/
```

---

## 18. Maintenance and Support

### Backup Strategy
- Daily automated MySQL backups
- Version control for code (Git)
- Database snapshots in cloud storage

### Update Procedures
1. Review Spring Boot security updates quarterly
2. Update dependencies monthly
3. Performance testing before major updates
4. Gradual rollout to production

### Troubleshooting Guide

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection Refused | MySQL not running | `sudo systemctl start mysql` |
| Port already in use | Another service using port | Change port in application.yml |
| Class not found | Missing Maven build | Run `mvn clean install` |
| Insufficient Balance Error | Low account balance | Credit account with funds |
| Account Inactive Error | Account status not ACTIVE | Update account status in database |

---

## 19. Compliance and Standards

### Code Standards
- Google Java Style Guide
- REST API best practices
- Spring Framework conventions

### Database Standards
- Normalized schema design
- Consistent naming conventions
- Proper indexing strategy

### Documentation Standards
- JavaDoc for public methods
- README files for each module
- Architecture Decision Records (ADR)

---

## 20. Contact and Support

**Project Lead:** Banking Microservices Team  
**Repository:** SIA_BANK  
**Documentation:** This design document  
**Last Updated:** February 13, 2026  
**Version:** 2.0.0

---

**End of Document**
