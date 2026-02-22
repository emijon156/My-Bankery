from bakery import Bakery

def main():
    bakery = Bakery()
    
    while (bakery.week < 5):
        if (bakery.week == 0):
        # no event. choose where to put moola.

            bakery.add_revenue()

            # ask player where money comes from
            choice1 = int(input())
            # ask player where money goes to
            choice2 = int(input())
            # ask player how much money to move
            n = float(input())

            bakery.transfer_cash(choice1, choice2, n)
            
        elif (bakery.week == 1):
        # cookie run kingdom: OVEN BREAAKK
            
            bakery.add_revenue()
            bakery.assets.equipment -= 1500

            # choose between (1) pay with credit or (2) dont refix oven
            choice = int(input())
            if (choice == 1):
                bakery.liabilities.acc_payable += 1500
                bakery.assets.equipment += 1500     

        elif (bakery.week == 2):
        # RATTLEEsSSSSSNKAE POWERWRWR (we go viral)

            bakery.add_revenue()
            bakery.add_revenue()
            bakery.add_revenue()
            bakery.add_revenue()
            bakery.add_revenue()

            # choose between (1) savings account or (2) use immediately
            choice = int(input())
            if (choice == 1):
                bakery.transfer_cash(1, 2, bakery.revenue)
            elif (choice == 2):
                bakery.add_expense(3, 7000)

        elif (bakery.week == 3):
        # eclair caught doing the illegal she dont have license to sell drugs u cant do that

            bakery.add_revenue()

            # choose between (1) pay fine or (2) stick it but no revenue for next week
            choice = int(input())
            if (choice == 1):
                bakery.assets.cash.savings -= 200
            elif (choice == 2):
                
                # i lowekyneuinely am too brainbusted to think of a better way to do this
                # but basically this is the last week just without adding revenue
                # so everything below this is end of this weeks report and the next week if u chose to not pay fine

                bakery.tick()
                bakery.week += 1

                # ok now starting au for week 5

                bakery.add_expense(2, -500)

                # ask player where money comes from
                choice1 = int(input())
                # ask player where money goes to
                choice2 = int(input())
                # ask player how much money to move
                n = float(input())

                bakery.transfer_cash(choice1, choice2, n)

                bakery.tick()
                return

        elif (bakery.week == 4):
        # no event. eat all the moola. wo bu care. this my last week so eclairs bankery can poop and burn.
            
            bakery.add_revenue()

            # ask player where money comes from
            choice1 = int(input())
            # ask player where money goes to
            choice2 = int(input())
            # ask player how much money to move
            n = float(input())

            bakery.transfer_cash(choice1, choice2, n)

        bakery.tick()
        bakery.week += 1

main()