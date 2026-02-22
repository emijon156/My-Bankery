class Expense:
    rent: float
    wage: float
    utility: float
    total: float

    def __init__(self):
        self.rent = 1
        self.wage = 1
        self.utility = 1
        self.total = self.rent + self.wage + self.utility
