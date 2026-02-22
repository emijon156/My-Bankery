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

import os
from dotenv import load_dotenv

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types as genai_types
import yfinance as yf

load_dotenv()
_GENAI_CLIENT = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY", ""),
    http_options={"api_version": "v1beta"},
)

_ECLAIR_SYSTEM = (
    "You are Eclair, an adorably nervous panda who owns the Bankery, a beloved pastry shop. "
    "You are learning about personal finance and speak in a warm, playful voice full of baking "
    "metaphors and gentle puns. You are honest about money — not preachy, just real — and always "
    "keep your response to exactly 2-3 short sentences. Never break character. "
    "Never use bullet points, lists, or formal language."
)



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
    EventRequest,
    EventResult,
    EclairReflectRequest,
    EclairReflectResponse,
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
# Narrative Event Choices
# ---------------------------------------------------------------------------

@app.post("/api/events/oven_repair", response_model=EventResult,
          summary="Issue 1: Oven breakdown — player chooses credit or bear-with-it")
def event_oven_repair(req: EventRequest):
    """
    choice_index 0 → charge $1,500 repair to credit card (loan up).
    choice_index 1 → bear with reduced capacity ($300 lost revenue).
    """
    result = game_engine.handle_oven_repair(
        req.checking_id, req.loan_id, req.choice_index
    )
    return EventResult(
        message=result["message"],
        checking=result.get("checking"),
        savings=result.get("savings"),
        loan=result.get("loan"),
        alert_type=result.get("alert_type", "info"),
    )


@app.post("/api/events/windfall", response_model=EventResult,
          summary="Issue 2: Viral-video windfall — HYSA vs impulse purchase")
def event_windfall(req: EventRequest):
    """
    choice_index 0 → deposit $2,000 windfall to High-Yield Savings.
    choice_index 1 → keep in checking, spend $500 on rose-gold whisk.
    """
    result = game_engine.handle_windfall(
        req.checking_id, req.savings_id, req.choice_index
    )
    return EventResult(
        message=result["message"],
        checking=result.get("checking"),
        savings=result.get("savings"),
        loan=result.get("loan"),
        alert_type=result.get("alert_type", "info"),
    )


@app.post("/api/events/permit_fine", response_model=EventResult,
          summary="Issue 3: Health-inspector permit fine — pay now or appeal")
def event_permit_fine(req: EventRequest):
    """
    choice_index 0 → pay $200 fine immediately.
    choice_index 1 → appeal: two weeks of closure costs $600 in lost revenue.
    """
    result = game_engine.handle_permit_fine(
        req.checking_id, req.choice_index
    )
    return EventResult(
        message=result["message"],
        checking=result.get("checking"),
        savings=result.get("savings"),
        loan=result.get("loan"),
        alert_type=result.get("alert_type", "info"),
    )


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
# Eclair Gemini Reflection
# ---------------------------------------------------------------------------

@app.post("/api/eclair/reflect", response_model=EclairReflectResponse,
          summary="Generate an in-character Eclair reflection on the player's finance-screen actions")
async def eclair_reflect(req: EclairReflectRequest):
    """
    Builds a prompt from the list of finance actions the player took this week,
    sends it to Gemini 1.5 Flash (async), and returns Eclair's 2-3 sentence
    in-character response. Falls back to a canned line on any API error.
    """
    if req.actions_summary:
        actions_text = "\n".join(f"• {a}" for a in req.actions_summary)
    else:
        actions_text = "• I didn't make any changes this week."

    prompt = (
        f"I'm Eclair, a panda who owns a bakery. This week (Week {req.week}) my advisor took these actions: {', '.join(req.actions_summary)}. "
        f"The current balances are: checking ${req.checking:,.0f}, savings ${req.savings:,.0f}, loan ${req.loan:,.0f}. "
        "Give me 1-2 sentences of actual, practical financial advice on whether these were good moves or what I should focus on next. "
        "Be blunt and mean brutal do not be nice."
    )
    try:
        response = await _GENAI_CLIENT.aio.models.generate_content(
            model="models/gemini-2.5-flash-lite",
            contents=prompt,
            config=genai_types.GenerateContentConfig(
                system_instruction=_ECLAIR_SYSTEM,
                max_output_tokens=2048,
                temperature=0.7,
            ),
        )
        candidate = response.candidates[0]
        finish_reason = candidate.finish_reason
        full_text = response.text.strip()
        print(f"[Eclair] OK (finish={finish_reason}): '{full_text[:60]}...'")
        return EclairReflectResponse(reflection=full_text)
    except Exception as e:
        print(f"[Eclair] Gemini API error: {e}")
        return EclairReflectResponse(
            reflection=(
                "Oof, my brain got a bit over-proofed there! "
                "But I trust every good baker learns from their batter mistakes, "
                "so let's keep our chins — and our profit margin — up!"
            )
        )


# ---------------------------------------------------------------------------
# Investments — live market data via yfinance
# ---------------------------------------------------------------------------

_TOP_TICKERS = ["SPY", "AAPL", "MSFT", "NVDA", "AMZN"]

@app.get("/api/investments/top", summary="Top 5 tickers with live price + daily % change")
def top_investments():
    """
    Returns current price and daily % change for the five tracked tickers.
    Uses yfinance fast_info for low-latency lookups.
    """
    results = []
    for symbol in _TOP_TICKERS:
        try:
            fi = yf.Ticker(symbol).fast_info
            price = round(float(fi.last_price), 2)
            prev  = float(fi.previous_close or fi.regular_market_previous_close or price)
            change_pct = round((price - prev) / prev * 100, 2) if prev else 0.0
            results.append({
                "symbol":           symbol,
                "price":            price,
                "daily_change_pct": change_pct,
            })
        except Exception as exc:
            results.append({
                "symbol":           symbol,
                "price":            0.0,
                "daily_change_pct": 0.0,
                "error":            str(exc),
            })
    return {"tickers": results}


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
