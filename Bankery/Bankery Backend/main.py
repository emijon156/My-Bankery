from fastapi import FastAPI
from pydantic import BaseModel
import nessie_client
import game_engine

app = FastAPI()

# Data models to ensure the frontend sends the right payload
class PlayerInit(BaseModel):
    player_name: str

class NextMonthRequest(BaseModel):
    checking_id: str
    savings_id: str
    loan_id: str

@app.post("/api/game/init")
def initialize_game(player: PlayerInit):
    """Creates the user in Nessie and sets up their starting balances."""
    # 1. Create the customer profile
    customer_id = nessie_client.create_customer(player.player_name)

    # 2. Create the Accounts (Assets & Liabilities)
    checking = nessie_client.create_account(customer_id, "Checking", "Cash Register", 3000)
    savings = nessie_client.create_account(customer_id, "Savings", "Safety Vault", 6000)

    # Note: Nessie treats loans a bit differently, but you can mock it as a credit account
    # starting with a balance that represents debt.
    loan = nessie_client.create_account(customer_id, "Credit Card", "The Drain (Loan)", 15000)

    return {
        "customer_id": customer_id,
        "accounts": {
            "checking_id": checking,
            "savings_id": savings,
            "loan_id": loan
        },
        "message": "Bankery initialized successfully. You have $10,000 in assets and $15,000 in debt."
    }

@app.post("/api/game/next-month")
def process_next_month(req: NextMonthRequest):
    """Processes expenses, interest, and events for the turn."""

    # Run the game engine logic
    alerts = game_engine.process_month(req.checking_id, req.savings_id, req.loan_id)

    # Fetch the fresh balances to send back to the SwiftUI app
    new_balances = {
        "checking": nessie_client.get_account_balance(req.checking_id),
        "savings": nessie_client.get_account_balance(req.savings_id),
        "loan": nessie_client.get_account_balance(req.loan_id)
    }

    return {
        "balances": new_balances,
        "alerts": alerts
    }
