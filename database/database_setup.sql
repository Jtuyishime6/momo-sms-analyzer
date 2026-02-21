CREATE DATABASE IF NOT EXISTS momo_analyzer_jdt;
USE momo_analyzer_jdt;

CREATE TABLE account_holders (
    holder_id INT AUTO_INCREMENT PRIMARY KEY,
    msisdn VARCHAR(15) UNIQUE,
    display_name VARCHAR(100),
    holder_type ENUM('personal', 'merchant', 'agent') DEFAULT 'personal',
    wallet_id VARCHAR(25),
    last_known_balance DECIMAL(15,2),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_msisdn (msisdn),
    INDEX idx_wallet_id (wallet_id)
);

CREATE TABLE tx_categories (
    cat_id INT AUTO_INCREMENT PRIMARY KEY,
    cat_name VARCHAR(60) UNIQUE NOT NULL,
    tx_type ENUM('payment', 'transfer', 'deposit', 'airtime') NOT NULL,
    notes TEXT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tx_type (tx_type)
);

CREATE TABLE sms_transactions (
    tx_id INT AUTO_INCREMENT PRIMARY KEY,
    raw_timestamp BIGINT NOT NULL,
    sms_content TEXT NOT NULL,
    human_date VARCHAR(55),
    ref_code VARCHAR(55),
    from_holder INT,
    to_holder INT,
    beneficiary_name VARCHAR(110),
    beneficiary_msisdn VARCHAR(15),
    cat_id INT NOT NULL,
    tx_amount DECIMAL(15,2) NOT NULL,
    currency_code VARCHAR(4) DEFAULT 'RWF',
    fee_charged DECIMAL(10,2) DEFAULT 0.00,
    closing_balance DECIMAL(15,2),
    tx_timestamp DATETIME NOT NULL,
    tx_status ENUM('completed', 'failed') DEFAULT 'completed',
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_from_holder FOREIGN KEY (from_holder) REFERENCES account_holders(holder_id),
    CONSTRAINT fk_to_holder FOREIGN KEY (to_holder) REFERENCES account_holders(holder_id),
    CONSTRAINT fk_cat FOREIGN KEY (cat_id) REFERENCES tx_categories(cat_id),
    INDEX idx_raw_ts (raw_timestamp),
    INDEX idx_tx_ts (tx_timestamp),
    INDEX idx_amount (tx_amount),
    INDEX idx_ref_code (ref_code),
    INDEX idx_ben_msisdn (beneficiary_msisdn),
    CONSTRAINT chk_positive_amount CHECK (tx_amount > 0),
    CONSTRAINT chk_non_neg_fee CHECK (fee_charged >= 0)
);

CREATE TABLE holder_tx_log (
    log_entry_id INT AUTO_INCREMENT PRIMARY KEY,
    holder_id INT NOT NULL,
    tx_id INT NOT NULL,
    participant_role ENUM('sender', 'receiver') NOT NULL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_holder FOREIGN KEY (holder_id) REFERENCES account_holders(holder_id),
    CONSTRAINT fk_log_tx FOREIGN KEY (tx_id) REFERENCES sms_transactions(tx_id),
    UNIQUE KEY uk_holder_tx_role (holder_id, tx_id, participant_role),
    INDEX idx_holder (holder_id),
    INDEX idx_tx (tx_id)
);

CREATE TABLE processing_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    severity ENUM('info', 'warning', 'error') NOT NULL,
    module VARCHAR(60) NOT NULL,
    event_detail TEXT NOT NULL,
    related_ref VARCHAR(55),
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_severity (severity),
    INDEX idx_event_time (event_time)
);

INSERT INTO tx_categories (cat_name, tx_type, notes) VALUES
('Peer Payment', 'payment', 'Direct payment sent to another account holder'),
('Wallet Transfer', 'transfer', 'Transfer initiated via phone number'),
('Cash In', 'deposit', 'Physical cash deposited into mobile wallet'),
('Airtime Top-up', 'airtime', 'Self-service airtime recharge');

INSERT INTO account_holders (msisdn, display_name, holder_type, wallet_id, last_known_balance) VALUES
('+250795963036', 'Jean de Dieu Tuyishime', 'personal', '36521838', 980.00),
('250791666666', 'Alice Mugabo', 'personal', '95464', NULL),
('250790777777', 'Patrick Nzabonimana', 'personal', NULL, NULL),
('250788999999', 'Grace Uwimana', 'personal', NULL, NULL),
('+250791888888', 'Eric Habimana', 'personal', NULL, NULL);

INSERT INTO sms_transactions (
    raw_timestamp, sms_content, human_date, ref_code,
    from_holder, to_holder, beneficiary_name, cat_id,
    tx_amount, fee_charged, closing_balance, tx_timestamp, tx_status
) VALUES
(1715351458724,
 'You have received 3000 RWF from Alice Mugabo (*********013) on your mobile money account at 2024-05-10 16:30:51. Message from sender: Happy Birthday. Your new balance: 3000 RWF. Financial Transaction Id: 76662021700.',
 '10 May 2024 4:30:58 PM', '76662021700', NULL, 1, 'Alice Mugabo', 2,
 3000.00, 0.00, 3000.00, '2024-05-10 16:30:51', 'completed'),

(1715351506754,
 'TxId: 73214484437. Your payment of 1500 RWF to Eric Habimana 99123 has been completed at 2024-05-10 16:31:39. Your new balance: 1500 RWF. Fee was 0 RWF.',
 '10 May 2024 4:31:46 PM', '73214484437', 1, NULL, 'Eric Habimana', 1,
 1500.00, 0.00, 1500.00, '2024-05-10 16:31:39', 'completed'),

(1715369560245,
 'TxId: 51732411227. Your payment of 800 RWF to Alice Mugabo 95464 has been completed at 2024-05-10 21:32:32. Your new balance: 700 RWF. Fee was 0 RWF.',
 '10 May 2024 9:32:40 PM', '51732411227', 1, 2, 'Alice Mugabo', 1,
 800.00, 0.00, 700.00, '2024-05-10 21:32:32', 'completed'),

(1715445936412,
 '*113*R*A bank deposit of 50000 RWF has been added to your mobile money account at 2024-05-11 18:43:49. Your NEW BALANCE: 50700 RWF. Cash Deposit::CASH::::0::250795963036.',
 '11 May 2024 6:45:36 PM', NULL, NULL, 1, 'CASH DEPOSIT', 3,
 50000.00, 0.00, 50700.00, '2024-05-11 18:43:49', 'completed'),

(1715506895734,
 '*162*TxId:13913173274*S*Your payment of 1000 RWF to Airtime with token has been completed at 2024-05-12 11:41:28. Fee was 0 RWF. Your new balance: 49700 RWF.',
 '12 May 2024 11:41:35 AM', '13913173274', 1, NULL, 'Airtime', 4,
 1000.00, 0.00, 49700.00, '2024-05-12 11:41:28', 'completed'),

(1715590000000,
 'TxId: 98765432100. Your payment of 2500 RWF to Patrick Nzabonimana 77321 has been completed at 2024-05-13 09:00:00. Your new balance: 47200 RWF. Fee was 100 RWF.',
 '13 May 2024 9:00:00 AM', '98765432100', 1, 3, 'Patrick Nzabonimana', 1,
 2500.00, 100.00, 47200.00, '2024-05-13 09:00:00', 'completed');

INSERT INTO holder_tx_log (holder_id, tx_id, participant_role) VALUES
(1, 1, 'receiver'),
(1, 2, 'sender'),
(1, 3, 'sender'),
(2, 3, 'receiver'),
(1, 4, 'receiver'),
(1, 5, 'sender'),
(1, 6, 'sender'),
(3, 6, 'receiver');

INSERT INTO processing_events (severity, module, event_detail, related_ref) VALUES
('info', 'xml_parser', 'XML file loaded successfully with 6 transaction records', NULL),
('info', 'sms_parser', 'All SMS bodies parsed and fields extracted without errors', NULL),
('warning', 'balance_monitor', 'Unusually large deposit detected — manual review recommended', '50000'),
('info', 'categorizer', 'Transaction type classification completed for all records', NULL),
('info', 'db_writer', 'All records committed to sms_transactions table', NULL);

SELECT 'Holder Summary Report:' AS report_section;
SELECT
    h.display_name,
    h.msisdn,
    h.last_known_balance,
    COUNT(htl.tx_id) AS total_transactions,
    SUM(CASE WHEN htl.participant_role = 'sender' THEN t.tx_amount ELSE 0 END) AS total_sent,
    SUM(CASE WHEN htl.participant_role = 'receiver' THEN t.tx_amount ELSE 0 END) AS total_received
FROM account_holders h
LEFT JOIN holder_tx_log htl ON h.holder_id = htl.holder_id
LEFT JOIN sms_transactions t ON htl.tx_id = t.tx_id
GROUP BY h.holder_id, h.display_name, h.msisdn, h.last_known_balance;

SELECT 'Category Breakdown:' AS report_section;
SELECT
    c.cat_name,
    c.tx_type,
    COUNT(t.tx_id) AS tx_count,
    SUM(t.tx_amount) AS total_volume
FROM tx_categories c
LEFT JOIN sms_transactions t ON c.cat_id = t.cat_id
GROUP BY c.cat_id, c.cat_name, c.tx_type;