Here's everything to paste into `docs/api_docs.md`:

```markdown
# MoMo SMS Transaction API Documentation

## Base URL
http://localhost:8000

## Authentication
All endpoints require Basic Authentication.

- Username: `jean`
- Password: `jeand123`

Credentials are sent as a Base64-encoded Authorization header on every request.

---

## Endpoints

### 1. GET /transactions
Returns all transactions in the system.

**Request:**
```
GET http://localhost:8000/transactions
Authorization: Basic amVhbjpqZWFuZDEyMw==
```

**Success Response — 200 OK:**
```json
{
  "status": "success",
  "count": 85,
  "data": [
    {
      "id": 1,
      "tx_id": "76662021700",
      "type": "incoming",
      "amount": 2000,
      "fee": 0,
      "balance_after": 2000,
      "counterpart": "Jane Smith",
      "timestamp": "2024-05-10 16:30:51",
      "readable_date": "10 May 2024 4:30:58 PM"
    }
  ]
}
```

**Error Response — 401 Unauthorized:**
```json
{
  "status": "error",
  "message": "Unauthorized"
}
```

---

### 2. GET /transactions/{id}
Returns a single transaction by ID.

**Request:**
```
GET http://localhost:8000/transactions/1
Authorization: Basic amVhbjpqZWFuZDEyMw==
```

**Success Response — 200 OK:**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "tx_id": "76662021700",
    "type": "incoming",
    "amount": 2000,
    "fee": 0,
    "balance_after": 2000,
    "counterpart": "Jane Smith",
    "timestamp": "2024-05-10 16:30:51",
    "readable_date": "10 May 2024 4:30:58 PM"
  }
}
```

**Error Response — 404 Not Found:**
```json
{
  "status": "error",
  "message": "Transaction not found"
}
```

**Error Response — 401 Unauthorized:**
```json
{
  "status": "error",
  "message": "Unauthorized"
}
```

---

### 3. POST /transactions
Creates a new transaction record.

**Request:**
```
POST http://localhost:8000/transactions
Authorization: Basic amVhbjpqZWFuZDEyMw==
Content-Type: application/json
```

**Request Body:**
```json
{
  "type": "incoming",
  "amount": 5000,
  "fee": 0,
  "balance_after": 10000,
  "counterpart": "Jane Smith",
  "timestamp": "2024-05-10 16:30:51"
}
```

**Success Response — 201 Created:**
```json
{
  "status": "success",
  "message": "Transaction created",
  "data": {
    "id": 86,
    "type": "incoming",
    "amount": 5000,
    "fee": 0,
    "balance_after": 10000,
    "counterpart": "Jane Smith",
    "timestamp": "2024-05-10 16:30:51"
  }
}
```

**Error Response — 400 Bad Request:**
```json
{
  "status": "error",
  "message": "Missing required fields"
}
```

**Error Response — 401 Unauthorized:**
```json
{
  "status": "error",
  "message": "Unauthorized"
}
```

---

### 4. PUT /transactions/{id}
Updates an existing transaction by ID.

**Request:**
```
PUT http://localhost:8000/transactions/1
Authorization: Basic amVhbjpqZWFuZDEyMw==
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 2500
}
```

**Success Response — 200 OK:**
```json
{
  "status": "success",
  "message": "Transaction updated",
  "data": {
    "id": 1,
    "type": "incoming",
    "amount": 2500,
    "fee": 0,
    "balance_after": 10000,
    "counterpart": "Jane Smith",
    "timestamp": "2024-05-10 16:30:51"
  }
}
```

**Error Response — 404 Not Found:**
```json
{
  "status": "error",
  "message": "Transaction not found"
}
```

**Error Response — 401 Unauthorized:**
```json
{
  "status": "error",
  "message": "Unauthorized"
}
```

---

### 5. DELETE /transactions/{id}
Deletes a transaction record by ID.

**Request:**
```
DELETE http://localhost:8000/transactions/1
Authorization: Basic amVhbjpqZWFuZDEyMw==
```

**Success Response — 200 OK:**
```json
{
  "status": "success",
  "message": "Transaction deleted"
}
```

**Error Response — 404 Not Found:**
```json
{
  "status": "error",
  "message": "Transaction not found"
}
```

**Error Response — 401 Unauthorized:**
```json
{
  "status": "error",
  "message": "Unauthorized"
}
```

---

## Error Code Summary

| Code | Meaning |
|------|---------|
| 200 OK | Request successful |
| 201 Created | New record created successfully |
| 400 Bad Request | Missing or invalid fields in request body |
| 401 Unauthorized | Missing or incorrect credentials |
| 404 Not Found | No record found with the given ID |
| 405 Method Not Allowed | HTTP method not supported on this endpoint |

---

## Transaction Fields

| Field | Type | Description |
|-------|------|-------------|
| id | int | Auto-assigned transaction ID |
| tx_id | string | MTN-assigned transaction ID from the SMS |
| type | string | incoming, outgoing, bank_deposit, withdrawal, debit |
| amount | int | Transaction amount in RWF |
| fee | int | Fee charged in RWF |
| balance_after | int | Account balance immediately after transaction |
| counterpart | string | Name of sender or recipient |
| timestamp | string | Date and time of transaction (YYYY-MM-DD HH:MM:SS) |
| readable_date | string | Human-readable date extracted from SMS |
```



