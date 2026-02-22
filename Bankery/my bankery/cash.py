class Cash:
    checking: float
    savings: float
    investment: float
    total: float

    def __init__(self):
        self.checking = 0
        self.savings = 0
        self.investment = 0
        self.total = self.checking + self.savings + self.investment
