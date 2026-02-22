from assets import Assets
from liabilities import Liabilities
from expense import Expense
import random

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
        revenue += random.randint(1500, 3600)
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
        return

    def transfer_cash(self, choice1: int, choice2: int, n: float) -> None:
        srcpt = self.get_cash(choice1)
        endpt = self.get_cash(choice2)
        if (srcpt < n):
            print(f"Not enough money in source account to transfer ${n}!")
        else:
            srcpt -= n
            endpt += n
        return
    
    def report(self) -> None:
        print("End of Week Report")
        print(f"Revenue: {self.revenue:.2f}")
        print(f"Expense: {self.expense:.2f}")
        print(f"Profit: {(self.revenue - self.expense):.2f}")
        print("Assets")
        print(f"Cash: {self.assets.cash.total:.2f}")
        print(f"Checking: {self.assets.cash.checking:.2f}")
        print(f"Savings: {self.assets.cash.savings:.2f}")
        print(f"Investment: {self.assets.cash.investment:.2f}")
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
        self.report()
        self.revenue = 0
        self.expense = 0
        self.apply_interest()
        return
