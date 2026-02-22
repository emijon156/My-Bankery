from assets import Assets
from liabilities import Liabilities
from expense import Expense
import random
import math

def round_down(n) -> float:
        return math.floor(n * 100) / 100

class Bakery:
    assets: Assets
    liabilities: Liabilities
    expense: Expense
    revenue: float
    week: float

    def __init__(self):
        self.assets = Assets()
        self.liabilities = Liabilities()
        self.expense = Expense()
        self.revenue = 0
        self.week = 0
    
    def net_worth(self) -> float:
        return self.assets.total - self.liabilities.total
    
    def get_cash(self, choice) -> float:
        if (choice == 1):
            return self.assets.cash.checking
        elif (choice == 2):
            return self.assets.cash.savings
        elif (choice == 3):
            return self.assets.cash.investment

    def add_revenue(self) -> None:
        revenue = random.randint(1500, 3600)
        self.revenue += revenue
        self.assets.cash.checking += revenue
        return
    
    def add_expense(self, choice: int, n: float) -> None:
        if (choice == 1):
            self.expense.rent += n
        elif (choice == 2):
            self.expense.wage += n
        elif (choice == 3):
            self.expense.utility += n
        return
    
    def pay_expense(self) -> None:
        if (self.assets.cash.total < self.expense.total):
            print("Not enough money! Must take a loan to pay expenses.")
        else:
            self.revenue -= self.expense.total
            self.assets.cash.checking -= self.expense.total
            self.expense.total -= self.expense.total
        return
    
    def add_loan(self, n: float) -> None:
        self.liabilities.loan += n
        self.assets.cash.checking += n
        return
    
    def pay_loan(self, n: float) -> None:
        if (self.assets.cash.checking < self.liabilities.loan):
            print(f"Not enough money in source account to pay ${n} of loan!")
        else:
            self.liabilities.loan -= n
            self.assets.cash.checking -= n
        return
    
    def apply_interest(self) -> None:
        self.assets.cash.savings *= 1.000962
        self.liabilities.loan *= 1.001923
        self.liabilities.acc_payable *= 1.004231
        return

    def transfer_cash(self, choice1: int, choice2: int, n: float) -> None:
        if (self.get_cash(choice1) < n):
            print(f"Not enough money in source account to transfer ${n}!")
        elif (choice1 == 1):
            if (choice2 == 2):
                self.assets.cash.checking -= n
                self.assets.cash.savings += n
            elif (choice2 == 3):
                self.assets.cash.checking -= n
                self.assets.cash.investment += n
        elif (choice1 == 2):
            if (choice2 == 1):
                self.assets.cash.savings -= n
                self.assets.cash.checking += n
            elif (choice2 == 3):
                self.assets.cash.savings -= n
                self.assets.cash.investment += n
        elif (choice1 == 3):
            if (choice2 == 1):
                self.assets.cash.investment -= n
                self.assets.cash.checking += n
            elif (choice2 == 2):
                self.assets.cash.investment -= n
                self.assets.cash.savings += n
        return
    
    def reset_expense(self) -> None:
        self.expense.rent = 500
        self.expense.wage = 500
        self.expense.utility = 50
        return

    def report(self) -> None:
        print(f"End of Week {self.week + 1} Report")
        print(f"Revenue: {self.revenue:.2f}")
        print(f"Expense: {self.expense.total:.2f}")
        print(f"Rent: {self.expense.rent:.2f}")
        print(f"Wages: {self.expense.wage:.2f}")
        print(f"Utilities: {self.expense.utility:.2f}")
        print(f"Profit: {(self.revenue - self.expense.total):.2f}")
        print("Assets")
        print(f"Cash: {self.assets.cash.total:.2f}")
        print(f"Checking: {round_down(self.assets.cash.checking):.2f}")
        print(f"Savings: {round_down(self.assets.cash.savings):.2f}")
        print(f"Investment: {round_down(self.assets.cash.investment):.2f}")
        print(f"Inventory: {self.assets.inventory:.2f}")
        print(f"Equipment: {self.assets.equipment:.2f}")
        print(f"Total Assets: {self.assets.total:.2f}")
        print("Liabilities")
        print(f"Loan: {self.liabilities.loan:.2f}")
        print(f"Account Payable: {self.liabilities.acc_payable:.2f}")
        print(f"Total Liabilities: {self.liabilities.total:.2f}")
        print(f"Net Worth {self.net_worth():.2f}")
        return

    def tick(self) -> None:
        if (self.revenue - self.expense.total < 0):
            print(f"Need to pay expenses! You might need to transfer money or take a loan.")
            return
        self.report()
        self.reset_expense()
        self.revenue = 0
        self.apply_interest()
        return
