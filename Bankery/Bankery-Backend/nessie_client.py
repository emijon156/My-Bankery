"""
nessie_client.py
Full Capital One Nessie API client covering every endpoint used by Bankery.

Endpoints wrapped:
  - Customers     (create, get, update)
  - Accounts      (create, get, list, update, delete)
  - Merchants     (create, get, list)
  - Deposits      (create, list)
  - Withdrawals   (create, list)
  - Transfers     (create, list)
  - Purchases     (create, list)
  - Bills         (create, list)
  - ATMs          (list)
  - Branches      (list)
"""

from __future__ import annotations

import os
from datetime import date
from typing import Any

import requests
from dotenv import load_dotenv

load_dotenv()
API_KEY: str = os.getenv("NESSIE_API_KEY", "")
BASE_URL: str = "http://api.reimaginebanking.com"


# ---------------------------------------------------------------------------
# Private HTTP helpers
# ---------------------------------------------------------------------------

def _url(path: str) -> str:
    return f"{BASE_URL}{path}?key={API_KEY}"


def _post(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    resp = requests.post(_url(path), json=payload, timeout=10)
    resp.raise_for_status()
    return resp.json()


def _get(path: str) -> Any:
    resp = requests.get(_url(path), timeout=10)
    resp.raise_for_status()
    return resp.json()


def _put(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    resp = requests.put(_url(path), json=payload, timeout=10)
    resp.raise_for_status()
    return resp.json()


def _delete(path: str) -> dict[str, Any]:
    resp = requests.delete(_url(path), timeout=10)
    resp.raise_for_status()
    return resp.json()


# ---------------------------------------------------------------------------
# Customers
# ---------------------------------------------------------------------------

def create_customer(first_name: str, last_name: str = "Baker") -> dict:
    payload = {
        "first_name": first_name,
        "last_name": last_name,
        "address": {
            "street_number": "1",
            "street_name": "Franklin St",
            "city": "Chapel Hill",
            "state": "NC",
            "zip": "27514",
        },
    }
    data = _post("/customers", payload)
    return data["objectCreated"]


def get_customer(customer_id: str) -> dict:
    return _get(f"/customers/{customer_id}")


def update_customer(customer_id: str, first_name: str, last_name: str) -> dict:
    payload = {
        "first_name": first_name,
        "last_name": last_name,
        "address": {
            "street_number": "1",
            "street_name": "Franklin St",
            "city": "Chapel Hill",
            "state": "NC",
            "zip": "27514",
        },
    }
    return _put(f"/customers/{customer_id}", payload)


# ---------------------------------------------------------------------------
# Accounts
# ---------------------------------------------------------------------------

def create_account(
    customer_id: str,
    acct_type: str,
    nickname: str,
    balance: int = 0,
) -> dict:
    """acct_type: 'Checking' | 'Savings' | 'Credit Card'"""
    payload = {
        "type": acct_type,
        "nickname": nickname,
        "rewards": 0,
        "balance": balance,
    }
    data = _post(f"/customers/{customer_id}/accounts", payload)
    return data["objectCreated"]


def get_account(account_id: str) -> dict:
    return _get(f"/accounts/{account_id}")


def get_account_balance(account_id: str) -> float:
    return float(_get(f"/accounts/{account_id}")["balance"])


def get_customer_accounts(customer_id: str) -> list[dict]:
    return _get(f"/customers/{customer_id}/accounts")


def update_account(account_id: str, nickname: str, acct_type: str) -> dict:
    return _put(f"/accounts/{account_id}", {"nickname": nickname, "type": acct_type})


def delete_account(account_id: str) -> dict:
    return _delete(f"/accounts/{account_id}")


# ---------------------------------------------------------------------------
# Merchants  (required for Purchases)
# ---------------------------------------------------------------------------

def create_merchant(name: str, category: str) -> dict:
    payload = {
        "name": name,
        "category": [category],
        "address": {
            "street_number": "1",
            "street_name": "Franklin St",
            "city": "Chapel Hill",
            "state": "NC",
            "zip": "27514",
        },
        "geocode": {"lat": 35.9132, "lng": -79.0558},
    }
    data = _post("/merchants", payload)
    return data["objectCreated"]


def get_merchant(merchant_id: str) -> dict:
    return _get(f"/merchants/{merchant_id}")


def get_all_merchants() -> list[dict]:
    return _get("/merchants")


# ---------------------------------------------------------------------------
# Deposits
# ---------------------------------------------------------------------------

def create_deposit(
    account_id: str,
    amount: float,
    description: str,
    transaction_date: str | None = None,
) -> dict:
    payload = {
        "medium": "balance",
        "transaction_date": transaction_date or str(date.today()),
        "amount": round(amount, 2),
        "description": description,
    }
    data = _post(f"/accounts/{account_id}/deposits", payload)
    return data.get("objectCreated", data)


def get_account_deposits(account_id: str) -> list[dict]:
    return _get(f"/accounts/{account_id}/deposits")


# ---------------------------------------------------------------------------
# Withdrawals
# ---------------------------------------------------------------------------

def create_withdrawal(
    account_id: str,
    amount: float,
    description: str,
    transaction_date: str | None = None,
) -> dict:
    payload = {
        "medium": "balance",
        "transaction_date": transaction_date or str(date.today()),
        "amount": round(amount, 2),
        "description": description,
    }
    data = _post(f"/accounts/{account_id}/withdrawals", payload)
    return data.get("objectCreated", data)


def get_account_withdrawals(account_id: str) -> list[dict]:
    return _get(f"/accounts/{account_id}/withdrawals")


# ---------------------------------------------------------------------------
# Transfers  (move money between two accounts)
# ---------------------------------------------------------------------------

def create_transfer(
    from_account_id: str,
    to_account_id: str,
    amount: float,
    description: str,
    transaction_date: str | None = None,
) -> dict:
    payload = {
        "medium": "balance",
        "payee_id": to_account_id,
        "transaction_date": transaction_date or str(date.today()),
        "amount": round(amount, 2),
        "description": description,
    }
    data = _post(f"/accounts/{from_account_id}/transfers", payload)
    return data.get("objectCreated", data)


def get_account_transfers(account_id: str) -> list[dict]:
    return _get(f"/accounts/{account_id}/transfers")


# ---------------------------------------------------------------------------
# Purchases  (spending at a merchant)
# ---------------------------------------------------------------------------

def create_purchase(
    account_id: str,
    merchant_id: str,
    amount: float,
    description: str,
    purchase_date: str | None = None,
) -> dict:
    payload = {
        "merchant_id": merchant_id,
        "medium": "balance",
        "purchase_date": purchase_date or str(date.today()),
        "amount": round(amount, 2),
        "description": description,
        "status": "pending",
    }
    data = _post(f"/accounts/{account_id}/purchases", payload)
    return data.get("objectCreated", data)


def get_account_purchases(account_id: str) -> list[dict]:
    return _get(f"/accounts/{account_id}/purchases")


# ---------------------------------------------------------------------------
# Bills  (recurring charges; tracked on the checking account)
# ---------------------------------------------------------------------------

def create_bill(
    account_id: str,
    amount: float,
    nickname: str,
    status: str = "pending",
) -> dict:
    payload = {
        "status": status,
        "payee": nickname,
        "nickname": nickname,
        "creation_date": str(date.today()),
        "payment_date": str(date.today()),
        "recurring_date": 1,
        "payment_amount": round(amount, 2),
    }
    data = _post(f"/accounts/{account_id}/bills", payload)
    return data.get("objectCreated", data)


def get_account_bills(account_id: str) -> list[dict]:
    return _get(f"/accounts/{account_id}/bills")


# ---------------------------------------------------------------------------
# ATMs & Branches  (informational)
# ---------------------------------------------------------------------------

def get_atms() -> list[dict]:
    return _get("/atms")


def get_branches() -> list[dict]:
    return _get("/branches")
