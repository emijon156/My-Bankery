"""
main.py
Bankery FastAPI backend — v2.0

Exposes the full Bankery game loop and every Nessie API surface to the
SwiftUI frontend over HTTP.

Run locally:
    uvicorn main:app --reload --port 8000

Endpoints
---------
Game lifecycle
  POST /api/game/init
  POST /api/game/next-week

Player actions
  POST /api/actions/take-loan
  POST /api/actions/pay-loan
  POST /api/actions/transfer
  POST /api/actions/buy-inventory
  POST /api/actions/upgrade-equipment

Account & transaction data
  GET  /api/customers/{customer_id}
  GET  /api/customers/{customer_id}/accounts
  GET  /api/accounts/{account_id}
  GET  /api/accounts/{account_id}/deposits
  GET  /api/accounts/{account_id}/withdrawals
  GET  /api/accounts/{account_id}/transfers
  GET  /api/accounts/{account_id}/purchases
  GET  /api/accounts/{account_id}/bills
  GET  /api/ledger

Merchant / location data
  GET  /api/merchants
  GET  /api/merchants/{merchant_id}
  GET  /api/atms
  GET  /api/branches

Report
  GET  /api/report
"""

from __future__ import annotations

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

import nessie_client
import game_engine
from models import (
    AccountIds,
    MerchantIds,
    NextWeekRequest,
    AddLoanRequest,
    PayLoanRequest,
    TransferRequest,
    BuyInventoryRequest,
    UpgradeEquipmentRequest,
)

app = FastAPI(
    title="Bankery API",
    version="2.0.0",
    description="Bakery finance simulation backed by the Capital One Nessie API.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Game Lifecycle
# ---------------------------------------------------------------------------

@app.post("/api/game/init", summary="Initialize a new Bankery game")
def initialize_game():
    """
    Creates a Nessie customer, 4 accounts (Checking, Savings, Investment, Loan),
    3 merchants, and seeds the weekly bill schedule.

    Returns all IDs that the frontend should persist to drive future API calls.
    """
    return game_engine.setup_game()


@app.post("/api/game/next-week", summary="Advance the game by one week")
def next_week(req: NextWeekRequest):
    """
    Processes one full week:
      1. Random sales revenue → Nessie deposit
      2. Fixed expense withdrawals / purchases
      3. APY credited to savings & investment
      4. Loan interest charged
      5. Equipment depreciation applied
      6. game_outcome returned: "ongoing" | "won" | "lost"

    The frontend sends back the current inventory and equipment values it
    received on the previous turn so the backend can apply changes statelessly.
    """
    return game_engine.process_week(
        req.accounts,
        req.merchants,
        req.week + 1,
        req.inventory,
        req.equipment,
    )


# ---------------------------------------------------------------------------
# Player Actions
# ---------------------------------------------------------------------------

@app.post("/api/actions/take-loan", summary="Take out an additional loan")
def take_loan(req: AddLoanRequest):
    result = game_engine.add_loan(req.checking_id, req.loan_id, req.amount)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/pay-loan", summary="Make a loan payment")
def pay_loan(req: PayLoanRequest):
    result = game_engine.pay_loan(req.checking_id, req.loan_id, req.amount)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/transfer", summary="Transfer funds between two accounts")
def transfer(req: TransferRequest):
    result = game_engine.transfer_cash(
        req.from_account_id, req.to_account_id, req.amount, req.description
    )
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/buy-inventory", summary="Buy bakery supplies (Purchases API)")
def buy_inventory(req: BuyInventoryRequest):
    result = game_engine.buy_inventory(
        req.checking_id, req.supply_merchant_id, req.amount
    )
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/upgrade-equipment", summary="Purchase an equipment upgrade (Purchases API)")
def upgrade_equipment(req: UpgradeEquipmentRequest):
    result = game_engine.upgrade_equipment(
        req.checking_id, req.equipment_merchant_id, req.amount
    )
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


# ---------------------------------------------------------------------------
# Customer & Account Data
# ---------------------------------------------------------------------------

@app.get("/api/accounts/{account_id}/deposits", summary="Deposit history for an account")
def get_deposits(account_id: str):
    return nessie_client.get_account_deposits(account_id)


@app.get("/api/accounts/{account_id}/withdrawals", summary="Withdrawal history for an account")
def get_withdrawals(account_id: str):
    return nessie_client.get_account_withdrawals(account_id)


@app.get("/api/accounts/{account_id}/transfers", summary="Transfer history for an account")
def get_transfers(account_id: str):
    return nessie_client.get_account_transfers(account_id)


@app.get("/api/accounts/{account_id}/purchases", summary="Purchase history for an account")
def get_purchases(account_id: str):
    return nessie_client.get_account_purchases(account_id)


@app.get("/api/ledger", summary="Full transaction ledger across all four game accounts")
def full_ledger(
    checking_id:   str = Query(..., description="Checking account ID"),
    savings_id:    str = Query(..., description="Savings account ID"),
    investment_id: str = Query(..., description="Investment account ID"),
    loan_id:       str = Query(..., description="Loan / Credit account ID"),
):
    """Returns deposits, withdrawals, transfers, purchases, and bills for each account."""
    accounts = AccountIds(
        checking_id=checking_id,
        savings_id=savings_id,
        investment_id=investment_id,
        loan_id=loan_id,
    )
    return game_engine.get_full_ledger(accounts)


# ---------------------------------------------------------------------------
# Weekly Report
# ---------------------------------------------------------------------------

@app.get("/api/report", summary="Formatted end-of-week financial report")
def weekly_report(
    checking_id:   str   = Query(...),
    savings_id:    str   = Query(...),
    investment_id: str   = Query(...),
    loan_id:       str   = Query(...),
    week:          int   = Query(0),
    revenue:       float = Query(0.0),
):
    """
    Returns a plain-text financial summary mirroring Bakery.report() from
    the 'my bakery' design — useful for debugging or a text-based UI.
    """
    accounts = AccountIds(
        checking_id=checking_id,
        savings_id=savings_id,
        investment_id=investment_id,
        loan_id=loan_id,
    )
    return {"report": game_engine.weekly_report(accounts, week, revenue)}
