import os
import requests
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("NESSIE_API_KEY")
BASE_URL = "http://api.reimaginebanking.com"

def create_customer(name: str):
    url = f"{BASE_URL}/customers?key={API_KEY}"
    payload = {
        "first_name": name,
        "last_name": "Baker",
        "address": {
            "street_number": "1",
            "street_name": "Franklin St",
            "city": "Chapel Hill",
            "state": "NC",
            "zip": "27514"
        }
    }
    response = requests.post(url, json=payload)
    return response.json()["objectCreated"]["_id"]

def create_account(customer_id: str, acct_type: str, nickname: str, starting_balance: int):
    url = f"{BASE_URL}/customers/{customer_id}/accounts?key={API_KEY}"
    # Nessie requires type to be 'Credit Card', 'Checking', or 'Savings'
    payload = {
        "type": acct_type,
        "nickname": nickname,
        "rewards": 0,
        "balance": starting_balance
    }
    response = requests.post(url, json=payload)
    return response.json()["objectCreated"]["_id"]

def post_transaction(account_id: str, trans_type: str, amount: int, description: str):
    # trans_type should be 'deposits' or 'withdrawals'
    url = f"{BASE_URL}/accounts/{account_id}/{trans_type}?key={API_KEY}"
    payload = {
        "medium": "balance",
        "transaction_date": "2026-02-21",
        "amount": amount,
        "description": description
    }
    requests.post(url, json=payload)

def get_account_balance(account_id: str):
    url = f"{BASE_URL}/accounts/{account_id}?key={API_KEY}"
    response = requests.get(url)
    return response.json()["balance"]
