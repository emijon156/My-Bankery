//
//  FinanceViewModel.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import Foundation
import Observation

@Observable
class FinanceViewModel {

    // MARK: - Balances – Assets (Cash)
    var checkingBalance: Double   = 3_000
    var savingsBalance: Double    = 6_000
    // Assets – Other
    var investmentBalance: Double = 2_000
    var inventoryBalance: Double  = 1_500
    var equipmentBalance: Double  = 4_000
    // Liabilities
    var loanBalance: Double            = 5_000
    var accountsPayableBalance: Double = 800

    var currentMonth: Int = 0

    // MARK: - Alerts & State
    var alerts: [GameAlert]   = []
    var outcome: GameOutcome  = .ongoing
    var isLoading: Bool       = false
    var errorMessage: String? = nil

    // MARK: - Computed

    var totalAssets: Double {
        checkingBalance + savingsBalance + investmentBalance + inventoryBalance + equipmentBalance
    }

    var totalLiabilities: Double {
        loanBalance + accountsPayableBalance
    }

    var netWorth: Double { totalAssets - totalLiabilities }

    var formattedMonth: String { "Week \(currentMonth)" }

    var assetRows: [BalanceSheetRow] {[
        BalanceSheetRow(label: "Checking",   amount: checkingBalance,   color: "blue"),
        BalanceSheetRow(label: "Savings",    amount: savingsBalance,    color: "green"),
        BalanceSheetRow(label: "Investment", amount: investmentBalance, color: "purple"),
        BalanceSheetRow(label: "Inventory",  amount: inventoryBalance,  color: "orange"),
        BalanceSheetRow(label: "Equipment",  amount: equipmentBalance,  color: "yellow"),
    ]}

    var liabilityRows: [BalanceSheetRow] {[
        BalanceSheetRow(label: "Loan",             amount: loanBalance,            color: "red"),
        BalanceSheetRow(label: "Accounts Payable", amount: accountsPayableBalance, color: "red"),
    ]}

    // MARK: - Private Account IDs
    private var checkingId: String = ""
    private var savingsId: String  = ""
    private var loanId: String     = ""

    // MARK: - Networking
    private let baseURL = "http://127.0.0.1:8000"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Init Game

    func initGame(playerName: String) async {
        isLoading    = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/api/game/init") else { return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody   = try? JSONSerialization.data(withJSONObject: ["player_name": playerName])

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)

            let result = try decoder.decode(InitResponse.self, from: data)
            checkingId = result.accounts.checkingId
            savingsId  = result.accounts.savingsId
            loanId     = result.accounts.loanId

            checkingBalance = 3000
            savingsBalance  = 6000
            loanBalance     = 15000
            currentMonth    = 0
            outcome         = .ongoing

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Next Month

    func nextMonth() async {
        guard outcome == .ongoing else { return }

        isLoading    = true
        errorMessage = nil
        alerts       = []

        guard let url = URL(string: "\(baseURL)/api/game/next-month") else { return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "checking_id": checkingId,
            "savings_id":  savingsId,
            "loan_id":     loanId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)

            let result      = try decoder.decode(NextMonthResponse.self, from: data)
            checkingBalance = result.balances.checking
            savingsBalance  = result.balances.savings
            loanBalance     = result.balances.loan
            alerts          = result.alerts
            currentMonth   += 1

            evaluateOutcome()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Reset

    func reset() {
        checkingBalance        = 3_000
        savingsBalance         = 6_000
        investmentBalance      = 2_000
        inventoryBalance       = 1_500
        equipmentBalance       = 4_000
        loanBalance            = 5_000
        accountsPayableBalance = 800
        currentMonth           = 0
        alerts                 = []
        outcome                = .ongoing
        checkingId             = ""
        savingsId              = ""
        loanId                 = ""
        errorMessage           = nil
    }

    // MARK: - Private Helpers

    private func evaluateOutcome() {
        if checkingBalance <= 0 {
            outcome = .lost
        } else if loanBalance <= 0 {
            outcome = .won
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
