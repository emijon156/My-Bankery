import random
import nessie_client

def process_month(checking_id: str, savings_id: str, loan_id: str):
    alerts = []

    # 1. Deduct Fixed Liabilities (The Drain)
    # Rent: $2000
    nessie_client.post_transaction(checking_id, "withdrawals", 2000, "Monthly Bakery Rent")
    # Loan Minimum: $400
    nessie_client.post_transaction(checking_id, "withdrawals", 400, "Loan Minimum Payment")

    # 2. Process Asset Growth (The Vault APY)
    # 4% Annual Yield = ~0.33% per month
    current_savings = nessie_client.get_account_balance(savings_id)
    monthly_interest = round(current_savings * (0.04 / 12), 2)

    if monthly_interest > 0:
        nessie_client.post_transaction(savings_id, "deposits", monthly_interest, "Vault APY Interest")
        alerts.append({"type": "success", "message": f"Your Vault earned ${monthly_interest} in interest!"})

    # 3. Process Liability Growth (The Loan Interest)
    # 10% Flat Rate on the remaining balance
    current_loan = nessie_client.get_account_balance(loan_id)
    loan_interest = round(current_loan * (0.10 / 12), 2)
    nessie_client.post_transaction(loan_id, "deposits", loan_interest, "Loan Interest Charge")

    # 4. RNG Events System
    event_chance = random.randint(1, 10)
    if event_chance == 1:
        # 10% chance the oven breaks
        nessie_client.post_transaction(checking_id, "withdrawals", 1500, "Emergency: Oven Repair")
        alerts.append({"type": "danger", "message": "Oh no! The main oven broke down. Repairs cost $1,500."})
    elif event_chance == 2:
        # 10% chance for a local catering gig
        nessie_client.post_transaction(checking_id, "deposits", 800, "Catering Gig")
        alerts.append({"type": "success", "message": "Eclair booked a huge catering gig! You earned an extra $800."})

    return alerts
