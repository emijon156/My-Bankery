from __future__ import annotations

import os
from dotenv import load_dotenv

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types as genai_types
import yfinance as yf

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

app = FastAPI(title="Bankery API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/api/game/init")
def initialize_game():
    return game_engine.setup_game()


@app.post("/api/game/next-week")
def next_week(req: NextWeekRequest):
    return game_engine.process_week(
        req.accounts,
        req.merchants,
        req.week + 1,
        req.inventory,
        req.equipment,
    )


@app.post("/api/actions/take-loan")
def take_loan(req: AddLoanRequest):
    result = game_engine.add_loan(req.checking_id, req.loan_id, req.amount)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/pay-loan")
def pay_loan(req: PayLoanRequest):
    result = game_engine.pay_loan(req.checking_id, req.loan_id, req.amount)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/transfer")
def transfer(req: TransferRequest):
    result = game_engine.transfer_cash(
        req.from_account_id, req.to_account_id, req.amount, req.description
    )
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/buy-inventory")
def buy_inventory(req: BuyInventoryRequest):
    result = game_engine.buy_inventory(
        req.checking_id, req.supply_merchant_id, req.amount
    )
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/actions/upgrade-equipment")
def upgrade_equipment(req: UpgradeEquipmentRequest):
    result = game_engine.upgrade_equipment(
        req.checking_id, req.equipment_merchant_id, req.amount
    )
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@app.post("/api/events/oven_repair", response_model=EventResult)
def event_oven_repair(req: EventRequest):
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


@app.post("/api/events/windfall", response_model=EventResult)
def event_windfall(req: EventRequest):
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


@app.post("/api/events/permit_fine", response_model=EventResult)
def event_permit_fine(req: EventRequest):
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


@app.get("/api/accounts/{account_id}/deposits")
def get_deposits(account_id: str):
    return nessie_client.get_account_deposits(account_id)


@app.get("/api/accounts/{account_id}/withdrawals")
def get_withdrawals(account_id: str):
    return nessie_client.get_account_withdrawals(account_id)


@app.get("/api/accounts/{account_id}/transfers")
def get_transfers(account_id: str):
    return nessie_client.get_account_transfers(account_id)


@app.get("/api/accounts/{account_id}/purchases")
def get_purchases(account_id: str):
    return nessie_client.get_account_purchases(account_id)


@app.get("/api/ledger")
def full_ledger(
    checking_id:   str = Query(...),
    savings_id:    str = Query(...),
    investment_id: str = Query(...),
    loan_id:       str = Query(...),
):
    accounts = AccountIds(
        checking_id=checking_id,
        savings_id=savings_id,
        investment_id=investment_id,
        loan_id=loan_id,
    )
    return game_engine.get_full_ledger(accounts)


@app.post("/api/eclair/reflect", response_model=EclairReflectResponse)
async def eclair_reflect(req: EclairReflectRequest):
    prompt = (
        f"I'm Eclair, a panda who owns a bakery. This week (Week {req.week}) my advisor took these actions: {', '.join(req.actions_summary)}. "
        f"The current balances are: checking ${req.checking:,.0f}, savings ${req.savings:,.0f}, loan ${req.loan:,.0f}. "
        "Give me 1-2 sentences of actual, practical financial advice on whether these were good moves or what I should focus on next. "
        "Be blunt and brutal, do not be nice."
    )
    try:
        response = await _GENAI_CLIENT.aio.models.generate_content(
            model="models/gemini-2.5-flash",
            contents=prompt,
            config=genai_types.GenerateContentConfig(
                system_instruction=_ECLAIR_SYSTEM,
                max_output_tokens=512,
                temperature=0.7,
                thinking_config=genai_types.ThinkingConfig(thinking_budget=0),
            ),
        )
        text = response.text
        if not text:
            raise ValueError(f"Empty response (finish={response.candidates[0].finish_reason if response.candidates else 'none'})")
        return EclairReflectResponse(reflection=text.strip())
    except Exception as e:
        print(f"[Eclair] error: {e}")
        return EclairReflectResponse(
            reflection=(
                "Oof, my brain got a bit over-proofed there! "
                "But I trust every good baker learns from their batter mistakes, "
                "so let's keep our chins — and our profit margin — up!"
            )
        )


_TOP_TICKERS = ["SPY", "AAPL", "MSFT", "NVDA", "AMZN"]

@app.get("/api/investments/top")
def top_investments():
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


@app.get("/api/report")
def weekly_report(
    checking_id:   str   = Query(...),
    savings_id:    str   = Query(...),
    investment_id: str   = Query(...),
    loan_id:       str   = Query(...),
    week:          int   = Query(0),
    revenue:       float = Query(0.0),
):
    accounts = AccountIds(
        checking_id=checking_id,
        savings_id=savings_id,
        investment_id=investment_id,
        loan_id=loan_id,
    )
    return {"report": game_engine.weekly_report(accounts, week, revenue)}
