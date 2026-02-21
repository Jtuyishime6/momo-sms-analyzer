from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import base64
from urllib.parse import urlparse
import os

records = []
next_record_id = 1

AUTH_USER = "jean"
AUTH_PASS = "jeand123"

def load_records():
    global records, next_record_id
    try:
        with open('data/processed/transactions.json', 'r') as f:
            records = json.load(f)
            next_record_id = max([r['id'] for r in records]) + 1 if records else 1
        print(f"Loaded {len(records)} transaction records")
    except FileNotFoundError:
        print("transactions.json not found — starting fresh.")
        records = []

def persist_records():
    os.makedirs('data/processed', exist_ok=True)
    with open('data/processed/transactions.json', 'w') as f:
        json.dump(records, f, indent=2)

class MoMoHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        if not self._check_auth():
            return
        path = urlparse(self.path).path
        if path == '/transactions':
            self._list_records()
        elif path.startswith('/transactions/'):
            self._get_record(path.split('/')[-1])
        else:
            self._error(404, "Route not found")

    def do_POST(self):
        if not self._check_auth():
            return
        if self.path == '/transactions':
            self._create_record()
        else:
            self._error(404, "Route not found")

    def do_PUT(self):
        if not self._check_auth():
            return
        if self.path.startswith('/transactions/'):
            self._update_record(self.path.split('/')[-1])
        else:
            self._error(404, "Route not found")

    def do_DELETE(self):
        if not self._check_auth():
            return
        if self.path.startswith('/transactions/'):
            self._delete_record(self.path.split('/')[-1])
        else:
            self._error(404, "Route not found")

    def _check_auth(self):
        header = self.headers.get('Authorization')
        if not header:
            self._deny_access()
            return False
        try:
            scheme, encoded = header.split(' ', 1)
            if scheme.lower() != 'basic':
                self._deny_access()
                return False
            user, pwd = base64.b64decode(encoded).decode().split(':', 1)
            if user == AUTH_USER and pwd == AUTH_PASS:
                return True
            self._deny_access()
            return False
        except Exception:
            self._deny_access()
            return False

    def _deny_access(self):
        self.send_response(401)
        self.send_header('WWW-Authenticate', 'Basic realm="MoMo Analyzer"')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'error': 'Unauthorized', 'hint': 'Provide valid Basic Auth credentials'}).encode())

    def _send_json(self, code, payload):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(payload, indent=2).encode())

    def _error(self, code, msg):
        self._send_json(code, {'error': True, 'message': msg})

    def _list_records(self):
        self._send_json(200, {'status': 'success', 'count': len(records), 'data': records})

    def _get_record(self, raw_id):
        try:
            rid = int(raw_id)
        except ValueError:
            self._error(400, "ID must be an integer")
            return
        match = next((r for r in records if r['id'] == rid), None)
        if match:
            self._send_json(200, {'status': 'success', 'data': match})
        else:
            self._error(404, f"No transaction found with id {rid}")

    def _create_record(self):
        global next_record_id
        try:
            length = int(self.headers['Content-Length'])
            body = json.loads(self.rfile.read(length).decode())
            body['id'] = next_record_id
            next_record_id += 1
            records.append(body)
            persist_records()
            self._send_json(201, {'status': 'success', 'message': 'Record created', 'data': body})
        except json.JSONDecodeError:
            self._error(400, "Malformed JSON body")
        except Exception as ex:
            self._error(500, str(ex))

    def _update_record(self, raw_id):
        try:
            rid = int(raw_id)
        except ValueError:
            self._error(400, "ID must be an integer")
            return
        match = next((r for r in records if r['id'] == rid), None)
        if not match:
            self._error(404, f"No transaction found with id {rid}")
            return
        try:
            length = int(self.headers['Content-Length'])
            updates = json.loads(self.rfile.read(length).decode())
            for k, v in updates.items():
                if k != 'id':
                    match[k] = v
            persist_records()
            self._send_json(200, {'status': 'success', 'message': 'Record updated', 'data': match})
        except json.JSONDecodeError:
            self._error(400, "Malformed JSON body")
        except Exception as ex:
            self._error(500, str(ex))

    def _delete_record(self, raw_id):
        global records
        try:
            rid = int(raw_id)
        except ValueError:
            self._error(400, "ID must be an integer")
            return
        match = next((r for r in records if r['id'] == rid), None)
        if match:
            records = [r for r in records if r['id'] != rid]
            persist_records()
            self._send_json(200, {'status': 'success', 'message': f'Transaction {rid} removed'})
        else:
            self._error(404, f"No transaction found with id {rid}")

    def log_message(self, fmt, *args):
        print(f"[{self.address_string()}] {fmt % args}")

def run(port=8000):
    load_records()
    server = HTTPServer(('', port), MoMoHandler)
    print(f"\n MoMo SMS Analyzer — REST API")
    print(f" Listening on http://localhost:{port}")
    print(f" Auth: Basic Auth  |  user: {AUTH_USER}  |  pass: {AUTH_PASS}")
    print(f"\n Endpoints:")
    print(f"   GET    /transactions")
    print(f"   GET    /transactions/<id>")
    print(f"   POST   /transactions")
    print(f"   PUT    /transactions/<id>")
    print(f"   DELETE /transactions/<id>")
    print(f"\n Ctrl+C to stop\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        server.shutdown()

if __name__ == '__main__':
    run()