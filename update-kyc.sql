-- Update KYC status to VERIFIED for testing
USE auth_db;
UPDATE users SET kyc_status = 'VERIFIED' WHERE username = 'testuser1';
SELECT id, username, email, kyc_status, customer_id FROM users WHERE username = 'testuser1';
