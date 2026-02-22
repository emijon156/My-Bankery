class Cash:
    checking: float
    savings: float
    investment: float

    def __init__(self):
        self.checking = 3000
        self.savings = 6000
        self.investment = 1000
    
    @property
    def total(self) -> float:
        return self.checking + self.savings + self.investment
