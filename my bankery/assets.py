from cash import Cash

class Assets:
    cash: Cash
    inventory: float
    equipment: float
    total: float

    def __init__(self):
        self.cash = Cash()
        self.inventory = 1
        self.equipment = 1
        self.total = self.cash.total + self.inventory + self.equipment
