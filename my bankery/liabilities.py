class Liabilities:
    loan: float
    acc_payable: float
    total: float

    def __init__(self):
        self.loan = 1
        self.acc_payable = 1
        self.total = self.loan + self.acc_payable
