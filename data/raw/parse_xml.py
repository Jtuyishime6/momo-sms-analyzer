import xml.etree.ElementTree as ET
import json
import re
from datetime import datetime


def parse_timestamp(ts):
    try:
        return datetime.fromtimestamp(int(ts) / 1000).strftime("%Y-%m-%d %H:%M:%S")
    except:
        return None


def classify_sms(body):
    if re.search(r"You have received", body):
        return "incoming"
    if re.search(r"bank deposit", body, re.IGNORECASE):
        return "bank_deposit"
    if re.search(r"withdrawn", body, re.IGNORECASE):
        return "withdrawal"
    if re.search(r"(transferred to|Your payment of)", body):
        return "outgoing"
    if re.search(r"one-time password", body, re.IGNORECASE):
        return "otp"
    if re.search(r"debit", body, re.IGNORECASE):
        return "debit"
    return "other"


def extract_amount(body):
    match = re.search(r"([\d,]+)\s*RWF", body)
    if match:
        return int(match.group(1).replace(",", ""))
    return None


def extract_counterpart(body, tx_type):
    if tx_type == "incoming":
        match = re.search(r"received \d+ RWF from ([A-Za-z ]+) \(", body)
        if match:
            return match.group(1).strip()
    if tx_type in ("outgoing", "bank_deposit", "withdrawal"):
        match = re.search(r"(?:transferred to|payment of [^to]+ to|withdrawn.*?agent: Agent )\s*([A-Za-z ]+?)[\s(]", body)
        if match:
            return match.group(1).strip()
    return None


def extract_balance(body):
    patterns = [
        r"[Nn]ew balance[:\s]*([\d,]+)\s*RWF",
        r"NEW BALANCE\s*:?([\d,]+)\s*RWF",
        r"new balance:([\d,]+)\s*RWF",
    ]
    for p in patterns:
        match = re.search(p, body)
        if match:
            return int(match.group(1).replace(",", ""))
    return None


def extract_fee(body):
    match = re.search(r"Fee (?:was|paid)[:\s]*([\d,]+)\s*RWF", body, re.IGNORECASE)
    if match:
        return int(match.group(1).replace(",", ""))
    return 0


def extract_tx_id(body):
    match = re.search(r"(?:TxId[:\s]*|Financial Transaction Id[:\s]*)([\d]+)", body)
    if match:
        return match.group(1)
    return None


def parse_xml(xml_path, output_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()

    records = []
    record_id = 1

    for sms in root.findall("sms"):
        body = sms.get("body", "")
        date_ms = sms.get("date", "0")
        readable = sms.get("readable_date", "")

        tx_type = classify_sms(body)

        if tx_type == "otp":
            continue

        amount = extract_amount(body)
        if amount is None:
            continue

        record = {
            "id": record_id,
            "tx_id": extract_tx_id(body),
            "type": tx_type,
            "amount": amount,
            "fee": extract_fee(body),
            "balance_after": extract_balance(body),
            "counterpart": extract_counterpart(body, tx_type),
            "timestamp": parse_timestamp(date_ms),
            "readable_date": readable,
            "raw_body": body
        }

        records.append(record)
        record_id += 1

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(records, f, indent=2, ensure_ascii=False)

    print(f"Parsed {len(records)} transactions -> {output_path}")
    return records


if __name__ == "__main__":
    parse_xml("modified_sms_v2.xml", "data/processed/transactions.json")