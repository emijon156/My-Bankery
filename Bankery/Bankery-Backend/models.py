"""
models.py
Pydantic data models for the Bankery game.

The class hierarchy mirrors the architecture in "my bankery":
  Cash → Assets → GameState
  Liabilities
  Expense

All Pydantic models are used both for internal game state and as
FastAPI request / response shapes to keep things consistent.
"""

from __future__ import annotations

from pydantic import BaseModel, Field, computed_field


# ---------------------------------------------------------------------------
# Nessie Account & Merchant ID bundles
# These are persisted by the Swift frontend and sent with every request.
# ---------------------------------------------------------------------------

class AccountIds(BaseModel):
    checking_id: str
    savings_id: str
    investment_id: str
    loan_id: str


class MerchantIds(BaseModel):
    supply_merchant_id: str       # Baker's Supply Co.  → inventory purchases
    equipment_merchant_id: str    # Pro Kitchen Equip.  → equipment upgrades / repairs
    utility_merchant_id: str      # Carolina Power & Light → utility bills


# ---------------------------------------------------------------------------
# Cash / Assets / Liabilities / Expense  (mirrors "my bankery" classes)
# ---------------------------------------------------------------------------

class CashState(BaseModel):
    """Mirrors cash.py — three sub-accounts."""
    checking: float = 0.0
    savings: float = 0.0
    investment: float = 0.0

    @computed_field  # type: ignore[prop-decorator]
    @property
    def total(self) -> float:
        return round(self.checking + self.savings + self.investment, 2)


class AssetsState(BaseModel):
    """Mirrors assets.py — cash + tangible assets."""
    cash: CashState = Field(default_factory=CashState)
    inventory: float = 1_000.0    # starting inventory value
    equipment: float = 5_000.0   # starting equipment value

    @computed_field  # type: ignore[prop-decorator]
    @property
    def total(self) -> float:
        return round(self.cash.total + self.inventory + self.equipment, 2)


class LiabilitiesState(BaseModel):
    """Mirrors liabilities.py — loan + accounts payable."""
    loan: float = 15_000.0
    acc_payable: float = 0.0

    @computed_field  # type: ignore[prop-decorator]
    @property
    def total(self) -> float:
        return round(self.loan + self.acc_payable, 2)


class ExpenseState(BaseModel):
    """Mirrors expense.py — three recurring expense categories."""
    rent: float = 2_000.0
    wage: float = 1_200.0
    utility: float = 300.0

    @computed_field  # type: ignore[prop-decorator]
    @property
    def total(self) -> float:
        return round(self.rent + self.wage + self.utility, 2)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def weekly(self) -> float:
        """One week's slice of all monthly expenses."""
        return round(self.total / 4, 2)


# ---------------------------------------------------------------------------
# Composite game state snapshot  (used in GET /api/game/state responses)
# ---------------------------------------------------------------------------

class GameSnapshot(BaseModel):
    customer_id: str
    accounts: AccountIds
    merchants: MerchantIds
    assets: AssetsState = Field(default_factory=AssetsState)
    liabilities: LiabilitiesState = Field(default_factory=LiabilitiesState)
    expenses: ExpenseState = Field(default_factory=ExpenseState)
    revenue: float = 0.0
    week: int = 0

    @computed_field  # type: ignore[prop-decorator]
    @property
    def net_worth(self) -> float:
        return round(self.assets.total - self.liabilities.total, 2)


# ---------------------------------------------------------------------------
# API Request models
# ---------------------------------------------------------------------------

class PlayerInitRequest(BaseModel):
    pass  # player name is hardcoded on the backend


class NextWeekRequest(BaseModel):
    accounts: AccountIds
    merchants: MerchantIds
    week: int
    inventory: float = 1_000.0   # current inventory value; backend applies weekly changes
    equipment: float = 5_000.0   # current equipment value; backend applies weekly depreciation


class AddLoanRequest(BaseModel):
    checking_id: str
    loan_id: str
    amount: float


class PayLoanRequest(BaseModel):
    checking_id: str
    loan_id: str
    amount: float


class TransferRequest(BaseModel):
    from_account_id: str
    to_account_id: str
    amount: float
    description: str = "Account Transfer"


class BuyInventoryRequest(BaseModel):
    checking_id: str
    supply_merchant_id: str
    amount: float


class UpgradeEquipmentRequest(BaseModel):
    checking_id: str
    equipment_merchant_id: str
    amount: float


# ---------------------------------------------------------------------------
# API Response models
# ---------------------------------------------------------------------------

class Alert(BaseModel):
    type: str       # "success" | "warning" | "danger" | "info"
    message: str


class WeekResult(BaseModel):
    week: int
    revenue: float
    fixed_expenses: float
    balances: dict[str, float]   # checking, savings, investment, loan
    net_worth: float
    inventory: float
    equipment: float
    game_outcome: str            # "ongoing" | "won" | "lost"
    alerts: list[Alert]


class EventRequest(BaseModel):
    """Sent by the frontend when the player makes a narrative-event choice."""
    choice_index: int      # 0 = option A, 1 = option B
    checking_id: str
    savings_id: str
    loan_id: str


class EventResult(BaseModel):
    """Returned by every /api/events/* endpoint."""
    message: str
    checking: float | None = None
    savings:  float | None = None
    loan:     float | None = None
    alert_type: str = "info"   # "success" | "warning" | "info"


class EclairReflectRequest(BaseModel):
    """Sent by the frontend to ask Eclair to reflect on the finance actions taken this week."""
    actions_summary: list[str]   # e.g. ["Transferred $500 from Checking to Savings", "Paid $200 toward loan"]
    checking:        float
    savings:         float
    loan:            float
    week:            int = 1


class EclairReflectResponse(BaseModel):
    """Eclair's Gemini-generated in-character reflection on the player's decision."""
    reflection: str
