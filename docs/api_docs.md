# MoMo SMS Transaction API Documentation

## Base URL
```
http://localhost:8000
```

## Authentication
All endpoints require Basic Authentication.

- **Username:** `jean`
- **Password:** `jeand123`

---

## Endpoints

### GET /transactions
Returns all transactions.

**PowerShell:**
```powershell
python -c "import urllib.request, base64; req = urllib.request.Request('http://localhost:8000/transactions'); req.add_header('Authorization', 'Basic ' + base64.b64encode(b'jean:jeand123').decode()); print(urllib.request.urlopen(req).read().decode())"
```

**Response:**
```json
{
  "status": "success",
  "count": 85,
  "data": [ ... ]
}
```

---

### GET /transactions/{id}
Returns a single transaction by ID.

**PowerShell:**
```powershell
python -c "import urllib.request, base64; req = urllib.request.Request('http://localhost:8000/transactions/1'); req.add_header('Authorization', 'Basic ' + base64.b64encode(b'jean:jeand123').decode()); print(urllib.request.urlopen(req).read().decode())"
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "type": "incoming",
    "amount": 2000,
    "fee": 0,
    "balance_after": 2000,
    "timestamp": "2024-05-10 16:30:51"
  }
}
```

---

### POST /transactions
Creates a new transaction.

**PowerShell:**
```powershell
python -c "import urllib.request, base64, json; data = json.dumps({'type':'incoming','amount':5000,'fee':0,'balance_after':10000,'timestamp':'2024-05-10 16:30:51'}).encode(); req = urllib.request.Request('http://localhost:8000/transactions', data=data, method='POST'); req.add_header('Authorization', 'Basic ' + base64.b64encode(b'jean:jeand123').decode()); req.add_header('Content-Type', 'application/json'); print(urllib.request.urlopen(req).read().decode())"
```

**Request Body:**
```json
{
  "type": "incoming",
  "amount": 5000,
  "fee": 0,
  "balance_after": 10000,
  "timestamp": "2024-05-10 16:30:51"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Transaction created",
  "data": { ... }
}
```

---

### PUT /transactions/{id}
Updates an existing transaction by ID.

**PowerShell:**
```powershell
python -c "import urllib.request, base64, json; data = json.dumps({'amount': 2500}).encode(); req = urllib.request.Request('http://localhost:8000/transactions/1', data=data, method='PUT'); req.add_header('Authorization', 'Basic ' + base64.b64encode(b'jean:jeand123').decode()); req.add_header('Content-Type', 'application/json'); print(urllib.request.urlopen(req).read().decode())"
```

**Request Body:**
```json
{
  "amount": 2500
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Transaction updated",
  "data": { ... }
}
```

---

### DELETE /transactions/{id}
Deletes a transaction by ID.

**PowerShell:**
```powershell
python -c "import urllib.request, base64; req = urllib.request.Request('http://localhost:8000/transactions/1', method='DELETE'); req.add_header('Authorization', 'Basic ' + base64.b64encode(b'jean:jeand123').decode()); print(urllib.request.urlopen(req).read().decode())"
```

**Response:**
```json
{
  "status": "success",
  "message": "Transaction deleted"
}
```

---

## Authentication Errors

If wrong credentials are provided, the server returns HTTP 401:
```json
{
  "status": "error",
  "message": "Unauthorized"
}
```

**Test with wrong credentials:**
```powershell
python -c "import urllib.request, base64; req = urllib.request.Request('http://localhost:8000/transactions'); req.add_header('Authorization', 'Basic ' + base64.b64encode(b'wrong:credentials').decode()); print(urllib.request.urlopen(req).read().decode())"
```

---

## Transaction Fields

| Field | Type | Description |
|-------|------|-------------|
| id | int | Auto-assigned transaction ID |
| tx_id | string | MTN-assigned transaction ID from SMS |
| type | string | incoming, outgoing, bank_deposit, withdrawal, debit |
| amount | int | Transaction amount in RWF |
| fee | int | Fee charged in RWF |
| balance_after | int | Account balance after transaction |
| counterpart | string | Name of sender or recipient |
| timestamp | string | Date and time of transaction |
| readable_date | string | Human-readable date from SMS |