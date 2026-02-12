# Banking Microservices - Design Document

## 1. Project Overview

**Project Name:** Banking Microservices  
**Version:** 1.0.0  
**Date:** January 31, 2026  
**Purpose:** A distributed microservices architecture for managing bank accounts and transactions with independent deployable services.

### Key Objectives
- Provide scalable account management functionality
- Enable transaction processing with financial operations
- Implement service-to-service communication using OpenFeign
- Ensure data consistency and reliability
- Support independent scaling of services

---

## 2. Architecture Overview

### 2.1 System Architecture
```
┌─────────────────────────────────────────────────────────┐
│                   API Gateway (Future)                  │
└────────────────┬──────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐       ┌───▼─────┐
   │ Account  │       │Transaction
   │ Service  │       │ Service
   │ :8080    │       │ :8081
   └────┬────┘       └───┬─────┘
        │                │
        │ (OpenFeign)    │
        └────────┬───────┘
                 │
        ┌────────▼────────┐
        │   MySQL 8.4.7   │
        ├─────────────────┤
        │ account_db      │
        │ transaction_db  │
        └─────────────────┘
```

### 2.2 Microservices
1. **Account Service** - Manages bank accounts and account operations
2. **Transaction Service** - Handles financial transactions and transfers

### 2.3 Communication
- **Internal Communication:** OpenFeign (Declarative REST Client)
- **Data Persistence:** Spring Data JPA with Hibernate ORM
- **Database:** MySQL 8.4.7

---

## 3. Service Specifications

### 3.1 Account Service

**Port:** 8080  
**Database:** account_db

#### Responsibilities
- Account creation and management
- Account status tracking (ACTIVE, INACTIVE, SUSPENDED, CLOSED)
- Credit operations (deposit funds)
- Debit operations (withdraw funds)
- Account inquiry and retrieval

#### Key Components

##### Entities
```
Account
├── id (Long) - Primary Key
├── accountNumber (String) - Unique identifier
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
├── customerId
├── balance
├── status
├── createdAt
└── updatedAt

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

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/accounts/{accountNumber}` | Retrieve account details |
| PUT | `/api/accounts/{accountNumber}/credit` | Credit funds to account |
| PUT | `/api/accounts/{accountNumber}/debit` | Debit funds from account |

---

### 3.2 Transaction Service

**Port:** 8081  
**Database:** transaction_db

#### Responsibilities
- Transaction logging and tracking
- Inter-account transfers
- Transaction history management
- Transaction status monitoring

#### Status
Currently a minimal implementation with base infrastructure. Can be extended to:
- Record all financial transactions
- Track transfer history
- Audit logging
- Transaction notifications

---

## 4. Database Design

### 4.1 Account Service Database (account_db)

```sql
CREATE TABLE accounts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  account_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id BIGINT NOT NULL,
  balance DECIMAL(19,2) NOT NULL,
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

## 5. Technology Stack

### Backend
- **Framework:** Spring Boot 3.0.0
- **Language:** Java 17
- **Build Tool:** Maven 3.9.9
- **JPA/ORM:** Spring Data JPA with Hibernate 6.1.5

### Database
- **Primary Database:** MySQL 8.4.7
- **Connection Pool:** HikariCP 5.0.1
- **JDBC Driver:** MySQL Connector/J 8.0.31

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
   cd account-service && mvn clean install -DskipTests
   cd ../transaction-service && mvn clean install -DskipTests
   ```

### 7.3 Running Services

**Account Service**
```bash
cd account-service
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
mvn spring-boot:run
```

**Transaction Service** (in separate terminal)
```bash
cd transaction-service
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
mvn spring-boot:run
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
**Repository:** Banking Microservices  
**Documentation:** This design document  
**Last Updated:** January 31, 2026  
**Version:** 1.0.0

---

**End of Document**
