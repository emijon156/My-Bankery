"""
game_engine.py
Bakery game logic — implements the Bakery turn-loop from "my bankery",
backed entirely by the Nessie API.

Architecture mirrors "my bankery":
  Assets  (Cash: checking / savings / investment,  inventory,  equipment)
  Liabilities  (loan,  acc_payable)
  Expense  (rent,  wage,  utility)
  Bakery methods:
    add_revenue, add_expense, pay_expense,
    add_loan, pay_loan, apply_interest,
    transfer_cash, report

All monetary state lives in Nessie — balances are always fetched fresh
from the API rather than stored locally.
"""

from __future__ import annotations

import random
from datetime import date
from typing import Dict

import nessie_client
from models import AccountIds, MerchantIds, Alert, ExpenseState

# ---------------------------------------------------------------------------
# In-memory balance cache
# Nessie balances are stale immediately after posting a transaction, so we
# track the authoritative running balance ourselves and only fall back to
# Nessie on a cold-start (first access for an account_id).
# ---------------------------------------------------------------------------
_balance_cache: Dict[str, float] = {}

def _get_balance(account_id: str) -> float:
    """Return cached balance, or fetch from Nessie and seed the cache."""
    if account_id not in _balance_cache:
        _balance_cache[account_id] = nessie_client.get_account_balance(account_id)
    return _balance_cache[account_id]

def _set_balance(account_id: str, balance: float) -> None:
    """Update the cache after an action changes a balance."""
    _balance_cache[account_id] = round(balance, 2)

def seed_balances(balances: Dict[str, float]) -> None:
    """Called after game init to pre-seed the cache with known starting values."""
    for account_id, bal in balances.items():
        _balance_cache[account_id] = float(bal)

# ---------------------------------------------------------------------------
# Financial constants
# ---------------------------------------------------------------------------

# Weekly revenue range (random bakery sales, from "my bakery" randint 1500–3600)
MIN_REVENUE: int = 1_500
MAX_REVENUE: int = 3_600

# Default monthly expenses (from expense.py defaults)
DEFAULT_EXPENSES = ExpenseState(rent=2_000.0, wage=1_200.0, utility=300.0)

# Interest rates — applied weekly
SAVINGS_WEEKLY_RATE: float = 0.04 / 52      # ~4 % annual   (Safety Vault)
INVESTMENT_WEEKLY_RATE: float = 0.07 / 52   # ~7 % annual   (Investment Fund)
LOAN_WEEKLY_RATE: float = 0.10 / 52         # ~10 % annual  (The Drain)


# ---------------------------------------------------------------------------
# Game initialization
# ---------------------------------------------------------------------------

def setup_game() -> dict:
    """
    Creates the full Nessie scaffolding for a new Bankery game:
      - 1 Customer (hardcoded name)
      - 4 Accounts  (Checking, Savings, Investment, Loan/Credit)
      - 3 Merchants (Supply, Equipment, Utility)
      - 3 Bills on checking (rent, wages, utilities)

    Returns all IDs so the Swift frontend can persist them.
    """
    today = str(date.today())
    player_name = "Eclair"

    # 1. Customer
    customer = nessie_client.create_customer(player_name)
    customer_id: str = customer["_id"]

    # 2. Accounts — mirrors Assets / Liabilities from models.py
    checking   = nessie_client.create_account(customer_id, "Checking",    "Cash Register",       3_000)
    savings    = nessie_client.create_account(customer_id, "Savings",     "Safety Vault",        6_000)
    investment = nessie_client.create_account(customer_id, "Savings",     "Investment Fund",     1_000)
    loan       = nessie_client.create_account(customer_id, "Credit Card", "The Drain (Loan)",   15_000)

    account_ids = {
        "checking_id":   checking["_id"],
        "savings_id":    savings["_id"],
        "investment_id": investment["_id"],
        "loan_id":       loan["_id"],
    }

    # 3. Merchants — used by purchases throughout the game
    supply_merchant    = nessie_client.create_merchant("Baker's Supply Co.",        "Grocery")
    equipment_merchant = nessie_client.create_merchant("Pro Kitchen Equipment",     "Equipment")
    utility_merchant   = nessie_client.create_merchant("Carolina Power & Light",    "Utilities")

    merchant_ids = {
        "supply_merchant_id":    supply_merchant["_id"],
        "equipment_merchant_id": equipment_merchant["_id"],
        "utility_merchant_id":   utility_merchant["_id"],
    }

    # 4. Seed recurring bills on the checking account (monthly amounts)
    nessie_client.create_bill(account_ids["checking_id"], DEFAULT_EXPENSES.rent,    "Monthly Bakery Rent")
    nessie_client.create_bill(account_ids["checking_id"], DEFAULT_EXPENSES.wage,    "Monthly Employee Wages")
    nessie_client.create_bill(account_ids["checking_id"], DEFAULT_EXPENSES.utility, "Monthly Utilities")

    # Seed the in-memory balance cache so subsequent action calls use correct values
    seed_balances({
        account_ids["checking_id"]:   3_000.0,
        account_ids["savings_id"]:    6_000.0,
        account_ids["investment_id"]: 1_000.0,
        account_ids["loan_id"]:      15_000.0,
    })

    return {
        "customer_id": customer_id,
        "accounts":    account_ids,
        "merchants":   merchant_ids,
        "starting_balances": {
            "checking":   3_000,
            "savings":    6_000,
            "investment": 1_000,
            "loan":      15_000,
        },
        "message": (
            f"Welcome to Bankery, {player_name}! "
            "You start with $10,000 in assets and $15,000 in debt. Good luck!"
        ),
    }


# ---------------------------------------------------------------------------
# Core weekly turn — mirrors Bakery's per-week methods
# ---------------------------------------------------------------------------

# Equipment depreciates 0.5 % per week (wear and tear)
EQUIPMENT_WEEKLY_DEPRECIATION: float = 0.005


def process_week(
    accounts: AccountIds,
    merchants: MerchantIds,
    week: int,
    inventory: float = 1_000.0,
    equipment: float = 5_000.0,
) -> dict:
    """
    Runs one full week of bakery operations:
      1. add_revenue         — random weekly sales deposited to checking
      2. pay_expense         — withdraw weekly slice of rent, wages, utilities
      3. apply_interest      — savings & investment APY credited; loan interest charged
      4. equipment deprec.   — equipment loses 0.5 % value per week
      5. game_outcome        — "won" (loan <= 0), "lost" (checking <= 0), else "ongoing"

    Returns a WeekResult-compatible dict with fresh balances, inventory,
    equipment, game_outcome, and alerts.
    """
    today = str(date.today())
    alerts: list[dict] = []

    # --- 1. add_revenue ---
    revenue = _add_revenue(accounts.checking_id, week, today)
    alerts.append({
        "type": "success",
        "message": f"Week {week} bakery sales: ${revenue:,.2f} deposited to Cash Register.",
    })

    # --- 2. pay_expense ---
    expense_alerts = _pay_expense(accounts, merchants, today)
    alerts.extend(expense_alerts)

    # --- 3. apply_interest ---
    interest_alerts = _apply_interest(accounts, today)
    alerts.extend(interest_alerts)

    # --- 4. Equipment depreciation ---
    equipment = round(equipment * (1 - EQUIPMENT_WEEKLY_DEPRECIATION), 2)

    # --- 5. Fetch fresh Nessie balances & determine outcome ---
    balances = _get_balances(accounts)
    total_assets = balances["checking"] + balances["savings"] + balances["investment"] + inventory + equipment
    net_worth    = round(total_assets - balances["loan"], 2)

    if balances["checking"] <= 0:
        game_outcome = "lost"
    elif balances["loan"] <= 0:
        game_outcome = "won"
    else:
        game_outcome = "ongoing"

    return {
        "week":            week,
        "revenue":         revenue,
        "fixed_expenses":  DEFAULT_EXPENSES.weekly,
        "balances":        balances,
        "net_worth":       net_worth,
        "inventory":       round(inventory, 2),
        "equipment":       round(equipment, 2),
        "game_outcome":    game_outcome,
        "alerts":          alerts,
    }


# ---------------------------------------------------------------------------
# Player-triggered actions  (all backed by Nessie)
# ---------------------------------------------------------------------------

def add_loan(checking_id: str, loan_id: str, amount: float) -> dict:
    """
    Take out a new loan.
    Nessie: deposit to checking (cash in hand) + deposit to loan (debt increases).
    """
    today        = str(date.today())
    checking_bal = _get_balance(checking_id)
    loan_bal     = _get_balance(loan_id)
    nessie_client.create_deposit(checking_id, amount, "Loan Disbursement",        today)
    nessie_client.create_deposit(loan_id,     amount, "New Loan Principal Added", today)
    new_checking = round(checking_bal + amount, 2)
    new_loan     = round(loan_bal     + amount, 2)
    _set_balance(checking_id, new_checking)
    _set_balance(loan_id,     new_loan)
    return {
        "checking": new_checking,
        "loan":     new_loan,
        "message":  f"Took out a loan of ${amount:,.2f}.",
    }


def pay_loan(checking_id: str, loan_id: str, amount: float) -> dict:
    """
    Pay down the loan.
    Nessie: withdrawal from checking + withdrawal from loan account (debt decreases).
    """
    today        = str(date.today())
    checking_bal = _get_balance(checking_id)
    loan_bal     = _get_balance(loan_id)

    if checking_bal < amount:
        return {
            "error": (
                f"Not enough money in Cash Register (${checking_bal:,.2f}) "
                f"to pay ${amount:,.2f} of loan!"
            )
        }

    payment = min(amount, loan_bal)
    nessie_client.create_withdrawal(checking_id, payment, "Loan Payment",          today)
    nessie_client.create_withdrawal(loan_id,     payment, "Loan Payment Received", today)
    new_checking = round(checking_bal - payment, 2)
    new_loan     = round(loan_bal     - payment, 2)
    _set_balance(checking_id, new_checking)
    _set_balance(loan_id,     new_loan)
    return {
        "checking": new_checking,
        "loan":     new_loan,
        "message":  f"Paid ${payment:,.2f} toward your loan.",
    }


def transfer_cash(
    from_account_id: str,
    to_account_id: str,
    amount: float,
    description: str = "Account Transfer",
) -> dict:
    """
    Move money between player accounts.
    Uses the Nessie Transfers API (distinct from deposits/withdrawals).
    """
    today    = str(date.today())
    src_bal  = _get_balance(from_account_id)

    if src_bal < amount:
        return {
            "error": (
                f"Not enough money in source account (${src_bal:,.2f}) "
                f"to transfer ${amount:,.2f}!"
            )
        }

    dst_bal = _get_balance(to_account_id)
    nessie_client.create_transfer(from_account_id, to_account_id, amount, description, today)
    new_src = round(src_bal - amount, 2)
    new_dst = round(dst_bal + amount, 2)
    _set_balance(from_account_id, new_src)
    _set_balance(to_account_id,   new_dst)
    return {
        "from_balance": new_src,
        "to_balance":   new_dst,
        "message":      f"Transferred ${amount:,.2f} successfully.",
    }


def buy_inventory(checking_id: str, supply_merchant_id: str, amount: float) -> dict:
    """Purchase bakery supplies using the Purchases API (supply merchant)."""
    today        = str(date.today())
    checking_bal = _get_balance(checking_id)

    if checking_bal < amount:
        return {"error": f"Not enough funds (${checking_bal:,.2f}) to buy ${amount:,.2f} in inventory."}

    nessie_client.create_purchase(
        checking_id, supply_merchant_id, amount, "Inventory Purchase", today
    )
    new_checking = round(checking_bal - amount, 2)
    _set_balance(checking_id, new_checking)
    return {
        "checking": new_checking,
        "message":  f"Purchased ${amount:,.2f} in bakery supplies.",
    }


def upgrade_equipment(checking_id: str, equipment_merchant_id: str, amount: float) -> dict:
    """Buy an equipment upgrade using the Purchases API (equipment merchant)."""
    today        = str(date.today())
    checking_bal = _get_balance(checking_id)

    if checking_bal < amount:
        return {"error": f"Not enough funds (${checking_bal:,.2f}) for equipment upgrade of ${amount:,.2f}."}

    nessie_client.create_purchase(
        checking_id, equipment_merchant_id, amount, "Equipment Upgrade", today
    )
    new_checking = round(checking_bal - amount, 2)
    _set_balance(checking_id, new_checking)
    return {
        "checking": new_checking,
        "message":  f"Purchased equipment upgrade for ${amount:,.2f}.",
    }


# ---------------------------------------------------------------------------
# Narrative event handlers  (called when player makes a story choice)
# ---------------------------------------------------------------------------

OVEN_REPAIR_COST:    float = 1_500.0
OVEN_CAPACITY_LOSS:  float = 300.0    # weekly revenue shortfall from using fewer ovens
WINDFALL_AMOUNT:     float = 2_000.0  # viral-video revenue boost
ROSE_GOLD_WHISK:     float = 500.0    # impulse-purchase price
PERMIT_FINE:         float = 200.0
APPEAL_INCOME_LOSS:  float = 600.0    # two weeks of ~$300/week lost while closed


def handle_oven_repair(checking_id: str, loan_id: str, choice_index: int) -> dict:
    """
    Issue 1: Oven breakdown.
    choice_index 0 — pay $1,500 on credit (loan increases).
    choice_index 1 — bear with remaining ovens ($300 lost revenue this week).
    """
    today = str(date.today())
    if choice_index == 0:
        # Put repair on credit card → loan balance grows
        loan_bal = _get_balance(loan_id)
        nessie_client.create_deposit(loan_id, OVEN_REPAIR_COST,
                                     "Oven Repair Charged to Credit", today)
        new_loan = round(loan_bal + OVEN_REPAIR_COST, 2)
        _set_balance(loan_id, new_loan)
        return {
            "checking":  _get_balance(checking_id),
            "loan":      new_loan,
            "message":   f"Oven repaired on credit. Loan increased by ${OVEN_REPAIR_COST:,.2f}.",
            "alert_type": "warning",
        }
    else:
        # Bear with reduced capacity → deduct lost revenue from checking
        checking_bal = _get_balance(checking_id)
        loss = min(OVEN_CAPACITY_LOSS, checking_bal)  # never overdraw
        if loss > 0:
            nessie_client.create_withdrawal(checking_id, loss,
                                            "Reduced Capacity Revenue Loss", today)
        new_checking = round(checking_bal - loss, 2)
        _set_balance(checking_id, new_checking)
        return {
            "checking":  new_checking,
            "loan":      _get_balance(loan_id),
            "message":   f"Managed with two ovens. Revenue reduced by ${loss:,.2f} this week.",
            "alert_type": "info",
        }


def handle_windfall(checking_id: str, savings_id: str, choice_index: int) -> dict:
    """
    Issue 2: Viral-video windfall.
    First deposits $2,000 to checking in both branches.
    choice_index 0 — move windfall to HYSA (savings).
    choice_index 1 — splurge on rose-gold whisk ($500 impulse buy).
    """
    today = str(date.today())
    # Common: deposit the viral earnings
    checking_bal = _get_balance(checking_id)
    nessie_client.create_deposit(checking_id, WINDFALL_AMOUNT,
                                 "Viral Video Revenue Boost", today)
    checking_bal = round(checking_bal + WINDFALL_AMOUNT, 2)
    _set_balance(checking_id, checking_bal)

    if choice_index == 0:
        # Transfer windfall to savings
        savings_bal = _get_balance(savings_id)
        nessie_client.create_transfer(checking_id, savings_id, WINDFALL_AMOUNT,
                                      "Windfall to HYSA", today)
        new_checking = round(checking_bal - WINDFALL_AMOUNT, 2)
        new_savings  = round(savings_bal  + WINDFALL_AMOUNT, 2)
        _set_balance(checking_id, new_checking)
        _set_balance(savings_id,  new_savings)
        return {
            "checking": new_checking,
            "savings":  new_savings,
            "message":  f"${WINDFALL_AMOUNT:,.2f} windfall deposited to your High-Yield Savings!",
            "alert_type": "success",
        }
    else:
        # Impulse purchase: rose-gold whisk
        cost = min(ROSE_GOLD_WHISK, checking_bal)
        if cost > 0:
            nessie_client.create_withdrawal(checking_id, cost,
                                            "Rose-Gold Whisk Impulse Purchase", today)
        new_checking = round(checking_bal - cost, 2)
        _set_balance(checking_id, new_checking)
        return {
            "checking": new_checking,
            "savings":  _get_balance(savings_id),
            "message":  f"${WINDFALL_AMOUNT:,.2f} windfall received! Spent ${cost:,.2f} on a rose-gold whisk.",
            "alert_type": "info",
        }


def handle_permit_fine(checking_id: str, choice_index: int) -> dict:
    """
    Issue 3: Health inspector permit fine ($200).
    choice_index 0 — pay the $200 fine immediately.
    choice_index 1 — appeal: doors closed 2 weeks → $600 of lost income.
    """
    today = str(date.today())
    if choice_index == 0:
        checking_bal = _get_balance(checking_id)
        payment = min(PERMIT_FINE, checking_bal)
        if payment > 0:
            nessie_client.create_withdrawal(checking_id, payment, "Permit Fine Payment", today)
        new_checking = round(checking_bal - payment, 2)
        _set_balance(checking_id, new_checking)
        return {
            "checking":  new_checking,
            "message":   f"Permit fine of ${payment:,.2f} paid. Bakery stays open!",
            "alert_type": "warning",
        }
    else:
        # Appeal: two-week closure means lost revenue
        checking_bal = _get_balance(checking_id)
        loss = min(APPEAL_INCOME_LOSS, checking_bal)
        if loss > 0:
            nessie_client.create_withdrawal(checking_id, loss,
                                            "Appeal Closure Revenue Loss", today)
        new_checking = round(checking_bal - loss, 2)
        _set_balance(checking_id, new_checking)
        return {
            "checking":  new_checking,
            "message":   f"Appeal filed. Closed for 2 weeks — lost ${loss:,.2f} in revenue.",
            "alert_type": "warning",
        }


# ---------------------------------------------------------------------------

def get_full_ledger(accounts: AccountIds) -> dict:
    """
    Returns all Nessie transaction records for every account.
    Used by the Report / History view in the frontend.
    """
    return {
        "checking": {
            "deposits":    nessie_client.get_account_deposits(accounts.checking_id),
            "withdrawals": nessie_client.get_account_withdrawals(accounts.checking_id),
            "transfers":   nessie_client.get_account_transfers(accounts.checking_id),
            "purchases":   nessie_client.get_account_purchases(accounts.checking_id),
            "bills":       nessie_client.get_account_bills(accounts.checking_id),
        },
        "savings": {
            "deposits":    nessie_client.get_account_deposits(accounts.savings_id),
            "withdrawals": nessie_client.get_account_withdrawals(accounts.savings_id),
        },
        "investment": {
            "deposits":    nessie_client.get_account_deposits(accounts.investment_id),
            "withdrawals": nessie_client.get_account_withdrawals(accounts.investment_id),
        },
        "loan": {
            "deposits":    nessie_client.get_account_deposits(accounts.loan_id),
            "withdrawals": nessie_client.get_account_withdrawals(accounts.loan_id),
        },
    }


def weekly_report(accounts: AccountIds, week: int, revenue: float) -> str:
    """
    Mirrors Bakery.report() from "my bakery" — returns a formatted string summary.
    """
    balances    = _get_balances(accounts)
    total_assets = balances["checking"] + balances["savings"] + balances["investment"]
    net_worth   = total_assets - balances["loan"]

    return (
        f"=== End of Week {week} Report ===\n"
        f"Revenue:      ${revenue:>10,.2f}\n"
        f"Expenses:     ${DEFAULT_EXPENSES.weekly:>10,.2f}  (weekly)\n"
        f"Profit:       ${revenue - DEFAULT_EXPENSES.weekly:>10,.2f}\n"
        f"\n-- Assets --\n"
        f"  Checking:   ${balances['checking']:>10,.2f}\n"
        f"  Savings:    ${balances['savings']:>10,.2f}\n"
        f"  Investment: ${balances['investment']:>10,.2f}\n"
        f"  Total:      ${total_assets:>10,.2f}\n"
        f"\n-- Liabilities --\n"
        f"  Loan:       ${balances['loan']:>10,.2f}\n"
        f"\nNet Worth:    ${net_worth:>10,.2f}\n"
    )


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _add_revenue(checking_id: str, week: int, today: str) -> float:
    revenue = float(random.randint(MIN_REVENUE, MAX_REVENUE))
    nessie_client.create_deposit(checking_id, revenue, f"Week {week} Bakery Sales", today)
    return revenue


def _pay_expense(accounts: AccountIds, merchants: MerchantIds, today: str) -> list[dict]:
    alerts: list[dict] = []
    weekly_rent    = round(DEFAULT_EXPENSES.rent    / 4, 2)
    weekly_wage    = round(DEFAULT_EXPENSES.wage    / 4, 2)
    weekly_utility = round(DEFAULT_EXPENSES.utility / 4, 2)

    nessie_client.create_withdrawal(
        accounts.checking_id, weekly_rent,  "Weekly Rent Payment", today
    )
    nessie_client.create_withdrawal(
        accounts.checking_id, weekly_wage,  "Weekly Wage Payments", today
    )
    # Utilities go through the Purchases API so there's a merchant record
    nessie_client.create_purchase(
        accounts.checking_id,
        merchants.utility_merchant_id,
        weekly_utility,
        "Weekly Utilities",
        today,
    )

    alerts.append({
        "type": "info",
        "message": (
            f"Weekly expenses paid — "
            f"Rent: ${weekly_rent:,.2f} | "
            f"Wages: ${weekly_wage:,.2f} | "
            f"Utilities: ${weekly_utility:,.2f}."
        ),
    })
    return alerts


def _apply_interest(accounts: AccountIds, today: str) -> list[dict]:
    """Mirrors Bakery.apply_interest() — APY on savings/investments, interest on loan."""
    alerts: list[dict] = []

    # Savings APY
    savings_bal = _get_balance(accounts.savings_id)
    savings_int = round(savings_bal * SAVINGS_WEEKLY_RATE, 2)
    if savings_int > 0:
        nessie_client.create_deposit(
            accounts.savings_id, savings_int, "Safety Vault Weekly APY", today
        )
        _set_balance(accounts.savings_id, round(savings_bal + savings_int, 2))
        alerts.append({
            "type": "success",
            "message": f"Your Safety Vault earned ${savings_int:.2f} in interest.",
        })

    # Investment return
    invest_bal = _get_balance(accounts.investment_id)
    invest_int = round(invest_bal * INVESTMENT_WEEKLY_RATE, 2)
    if invest_int > 0:
        nessie_client.create_deposit(
            accounts.investment_id, invest_int, "Investment Fund Weekly Return", today
        )
        _set_balance(accounts.investment_id, round(invest_bal + invest_int, 2))
        alerts.append({
            "type": "success",
            "message": f"Your Investment Fund earned ${invest_int:.2f} this week.",
        })

    # Loan interest (debt grows)
    loan_bal  = _get_balance(accounts.loan_id)
    loan_int  = round(loan_bal * LOAN_WEEKLY_RATE, 2)
    if loan_int > 0:
        nessie_client.create_deposit(
            accounts.loan_id, loan_int, "Weekly Loan Interest Charge", today
        )
        _set_balance(accounts.loan_id, round(loan_bal + loan_int, 2))
        alerts.append({
            "type": "warning",
            "message": f"Your loan accrued ${loan_int:.2f} in interest this week.",
        })

    return alerts


def _get_balances(accounts: AccountIds) -> dict[str, float]:
    return {
        "checking":   _get_balance(accounts.checking_id),
        "savings":    _get_balance(accounts.savings_id),
        "investment": _get_balance(accounts.investment_id),
        "loan":       _get_balance(accounts.loan_id),
    }
