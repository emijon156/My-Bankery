class Expense:
    rent: float
    wage: float
    utility: float

    def __init__(self):
        self.rent = 500
        self.wage = 500
        self.utility = 50

    @property
    def total(self) -> float:
        return self.rent + self.wage + self.utility
