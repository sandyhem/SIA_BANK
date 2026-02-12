CREATE TABLE transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    sender_account VARCHAR(255) NOT NULL,
    receiver_account VARCHAR(255) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    status ENUM('SUCCESS', 'FAILED', 'PENDING') NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);