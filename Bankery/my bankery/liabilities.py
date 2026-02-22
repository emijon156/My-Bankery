class Liabilities:
    loan: float
    acc_payable: float

    def __init__(self):
        self.loan = 15000
        self.acc_payable = 0
    
    @property
    def total(self) -> float:
        return self.loan + self.acc_payable
