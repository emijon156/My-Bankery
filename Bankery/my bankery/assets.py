from cash import Cash

class Assets:
    cash: Cash
    inventory: float
    equipment: float

    def __init__(self):
        self.cash = Cash()
        self.inventory = 2000
        self.equipment = 5000
        
    @property
    def total(self) -> float:
        return self.cash.total + self.inventory + self.equipment