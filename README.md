# MoMo SMS Analyzer

Enterprise-grade fullstack application that ingests MoMo SMS data from XML, runs it through an ETL pipeline, stores transactions in a relational MySQL database, and surfaces insights through a REST API and web dashboard.

---

## Team

**Jean de Dieu Tuyishime** — <j.tuyishime6@alustudent.com>

---

## Scrum Board

[View Project Board](https://github.com/users/Jtuyishime6/projects/2)

---

## Repository

```
https://github.com/Jtuyishime6/momo-sms-analyzer
```

---

## Project Layout

```
momo-sms-analyzer/
├── api/
│   └── api_server.py          # REST API (Python stdlib only)
├── data/
│   ├── raw/
│   │   └── modified_sms_v2.xml
│   └── processed/
│       └── transactions.json
├── database/
│   └── database_setup.sql     # Full DDL + sample data
├── docs/
│   ├── erd_diagram.png
│   └── api_docs.md
├── dsa/
│   ├── xml_parser.py
│   └── search_comparison.py
├── examples/
│   └── json_schemas.json
├── screenshots/
├── scripts/
│   ├── test_commands.sh
│   ├── export_json.sh
│   └── serve_frontend.sh
└── tests/
```

---

## Database Design

The schema lives in `database/database_setup.sql` and comprises five tables:

**account_holders** — wallet owner profiles extracted from SMS text (phone, name, wallet ID, balance).

**tx_categories** — lookup table for four transaction types: `payment`, `transfer`, `deposit`, `airtime`.

**sms_transactions** — central fact table storing the raw SMS payload alongside all extracted fields (amount, fee, closing balance, timestamps, beneficiary details, and a FK to the category).

**holder_tx_log** — junction table resolving the many-to-many relationship between holders and transactions; each row records whether the holder was the `sender` or `receiver`.

**processing_events** — operational log capturing `info`, `warning`, and `error` events from each pipeline stage.

Key constraints: `CHECK (tx_amount > 0)`, `CHECK (fee_charged >= 0)`, unique composite key on `(holder_id, tx_id, participant_role)`, and full referential integrity via `FOREIGN KEY` constraints.

---

## Quick Start

### Prerequisites

- Python 3.x
- MySQL 8+

### 1. Clone

```bash
git clone https://github.com/Jtuyishime6/momo-sms-analyzer.git
cd momo-sms-analyzer
```

### 2. Set up the database

```bash
mysql -u root -p < database/database_setup.sql
```

### 3. Place XML data

Copy `modified_sms_v2.xml` into `data/raw/`.

### 4. Parse XML → JSON

```bash
python dsa/xml_parser.py
```

Output: `data/processed/transactions.json`

### 5. Run DSA performance comparison

```bash
python dsa/search_comparison.py
```

Benchmarks linear search vs O(1) dictionary lookup.

---

## Running the API

```bash
python api/api_server.py
```

Server starts at `http://localhost:8000`

| Credential | Value |
|---|---|
| Username | `jean` |
| Password | `jeand123` |

### Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/transactions` | List all transactions |
| GET | `/transactions/<id>` | Fetch single transaction |
| POST | `/transactions` | Create transaction |
| PUT | `/transactions/<id>` | Update transaction |
| DELETE | `/transactions/<id>` | Delete transaction |

---

## Testing

### Automated script

```bash
chmod +x scripts/test_commands.sh
bash scripts/test_commands.sh
```

### cURL examples

```bash
# List all
curl -X GET http://localhost:8000/transactions -u jean:jeand123

# Single record
curl -X GET http://localhost:8000/transactions/1 -u jean:jeand123

# Create
curl -X POST http://localhost:8000/transactions \
  -u jean:jeand123 \
  -H "Content-Type: application/json" \
  -d '{"amount": 5000.0, "recipient_name": "Grace Uwimana", "transaction_type": "payment"}'

# Update
curl -X PUT http://localhost:8000/transactions/1 \
  -u jean:jeand123 \
  -H "Content-Type: application/json" \
  -d '{"amount": 3500.0}'

# Delete
curl -X DELETE http://localhost:8000/transactions/1 -u jean:jeand123

# Invalid credentials (expect 401)
curl -X GET http://localhost:8000/transactions -u wrong:creds
```

### Postman

1. Import endpoints from `docs/api_docs.md`
2. Auth type → **Basic Auth**
3. Username: `jean` / Password: `jeand123`

### Unit tests

```bash
python -m pytest tests/
```

## DSA - Data Structures & Algorithms

### Search Comparison

The `dsa/dsa_search.py` script compares two search methods on the parsed transactions:

| Method | Time Complexity | Description |
|--------|----------------|-------------|
| Linear Search | O(n) | Scans each record one by one until ID is found |
| Dictionary Lookup | O(1) | Direct key access using a hash table |

### Run the DSA Test

```bash
python dsa/dsa_search.py
```

### How It Works

- **Linear Search** — iterates through the full list of transactions comparing each ID
- **Dictionary Lookup** — builds a `{id: transaction}` dict once, then fetches by key instantly

### Why Dictionary Lookup is Faster

Python dictionaries use hash tables internally. Given a key, Python computes its hash and jumps directly to the value in memory — no scanning required. With 1,693 SMS records, dictionary lookup is significantly faster than linear search for repeated ID queries.

### Alternative Data Structures

- **B-Tree** — used by MySQL indexes, O(log n), optimised for large datasets on disk
- **Binary Search Tree** — O(log n), good when data needs to stay sorted
- **Sorted list + Binary Search** — O(log n) with lower memory overhead than a dict

---

## Frontend Dashboard

```bash
bash scripts/export_json.sh   # Export latest data
bash scripts/serve_frontend.sh  # Serve on port 8000
```

Open `http://localhost:8000` in your browser.

---

## Sample SQL Queries

```sql
-- Recent transactions with holder info
SELECT t.ref_code, t.tx_amount, t.tx_timestamp,
       s.msisdn AS sender, r.msisdn AS receiver,
       c.cat_name
FROM sms_transactions t
LEFT JOIN account_holders s ON t.from_holder = s.holder_id
LEFT JOIN account_holders r ON t.to_holder = r.holder_id
JOIN tx_categories c ON t.cat_id = c.cat_id
ORDER BY t.tx_timestamp DESC
LIMIT 10;

-- Volume by category
SELECT c.cat_name, COUNT(*) AS tx_count,
       SUM(t.tx_amount) AS total_volume,
       AVG(t.tx_amount) AS avg_amount
FROM sms_transactions t
JOIN tx_categories c ON t.cat_id = c.cat_id
WHERE t.tx_status = 'completed'
GROUP BY c.cat_id
ORDER BY total_volume DESC;
```

---

## Data Flow

```
XML File → xml_parser.py → transactions.json → api_server.py → HTTP responses
                                     ↓
                            database_setup.sql → MySQL
```
