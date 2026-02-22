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

    // MARK: - Balances (populated entirely from the backend — no hardcoded values)
    var checkingBalance: Double   = 0
    var savingsBalance: Double    = 0
    var investmentBalance: Double = 0
    var inventoryValue: Double    = 0
    var equipmentValue: Double    = 0
    var loanBalance: Double       = 0
    var currentWeek: Int          = 0

    // MARK: - UI State
    var alerts: [GameAlert]   = []
    var outcome: GameOutcome  = .ongoing
    var isLoading: Bool       = false
    var errorMessage: String? = nil
    var actionLoading: Bool   = false
    var actionError: String?  = nil

    // MARK: - Private Session IDs (persisted across turns, sent with every request)
    private var accountIDs: AccountIDs?
    private var merchantIDs: MerchantIDs?

    // MARK: - Computed

    var totalAssets: Double {
        checkingBalance + savingsBalance + investmentBalance + inventoryValue + equipmentValue
    }

    var totalLiabilities: Double { loanBalance }

    var netWorth: Double { totalAssets - totalLiabilities }

    var formattedWeek: String { "Week \(currentWeek)" }

    var assetRows: [BalanceSheetRow] {[
        BalanceSheetRow(label: "Checking",   amount: checkingBalance,   color: "blue"),
        BalanceSheetRow(label: "Savings",    amount: savingsBalance,    color: "green"),
        BalanceSheetRow(label: "Investment", amount: investmentBalance, color: "purple"),
        BalanceSheetRow(label: "Inventory",  amount: inventoryValue,    color: "orange"),
        BalanceSheetRow(label: "Equipment",  amount: equipmentValue,    color: "yellow"),
    ]}

    var liabilityRows: [BalanceSheetRow] {[
        BalanceSheetRow(label: "Loan", amount: loanBalance, color: "red"),
    ]}

    // MARK: - Networking
    private let baseURL = "http://MacBook-Pro-1513.local:8000"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Init Game

    func initGame() async {
        isLoading    = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/api/game/init") else { return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody   = "{}" .data(using: .utf8)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)

            let result  = try decoder.decode(InitResponse.self, from: data)
            accountIDs  = result.accounts
            merchantIDs = result.merchants

            // Set starting balances from what the backend created in Nessie
            checkingBalance   = result.startingBalances.checking
            savingsBalance    = result.startingBalances.savings
            investmentBalance = result.startingBalances.investment
            loanBalance       = result.startingBalances.loan

            // Tangible assets use the backend's AssetsState defaults
            inventoryValue  = 1_000
            equipmentValue  = 5_000

            currentWeek = 0
            outcome     = .ongoing
            alerts      = []

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Next Week

    func nextWeek() async {
        guard outcome == .ongoing,
              let accounts  = accountIDs,
              let merchants = merchantIDs else { return }

        isLoading    = true
        errorMessage = nil
        alerts       = []

        guard let url = URL(string: "\(baseURL)/api/game/next-week") else { return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = NextWeekRequest(
            accounts:   accounts,
            merchants:  merchants,
            week:       currentWeek,
            inventory:  inventoryValue,
            equipment:  equipmentValue
        )
        request.httpBody = try? encoder.encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)

            let result        = try decoder.decode(WeekResult.self, from: data)
            checkingBalance   = result.balances.checking
            savingsBalance    = result.balances.savings
            investmentBalance = result.balances.investment
            loanBalance       = result.balances.loan
            inventoryValue    = result.inventory
            equipmentValue    = result.equipment
            currentWeek       = result.week
            alerts            = result.alerts

            switch result.gameOutcome {
            case "won":  outcome = .won
            case "lost": outcome = .lost
            default:     outcome = .ongoing
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Reset

    func reset() {
        checkingBalance   = 0
        savingsBalance    = 0
        investmentBalance = 0
        inventoryValue    = 0
        equipmentValue    = 0
        loanBalance       = 0
        currentWeek       = 0
        alerts            = []
        outcome           = .ongoing
        errorMessage      = nil
        actionLoading     = false
        actionError       = nil
        accountIDs        = nil
        merchantIDs       = nil
    }

    // MARK: - Private Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func accountID(for type: AccountType) -> String? {
        switch type {
        case .checking:   return accountIDs?.checkingId
        case .savings:    return accountIDs?.savingsId
        case .investment: return accountIDs?.investmentId
        }
    }

    private func applyBalance(for type: AccountType, value: Double) {
        switch type {
        case .checking:   checkingBalance   = value
        case .savings:    savingsBalance    = value
        case .investment: investmentBalance = value
        }
    }

    // MARK: - Transfer

    func transfer(from: AccountType, to: AccountType, amount: Double) async {
        guard let fromID = accountID(for: from),
              let toID   = accountID(for: to) else { return }
        actionLoading = true
        actionError   = nil

        guard let url = URL(string: "\(baseURL)/api/actions/transfer") else { actionLoading = false; return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "from_account_id": fromID,
            "to_account_id":   toID,
            "amount":          amount,
            "description":     "Transfer: \(from.rawValue) to \(to.rawValue)"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            let result = try decoder.decode(ActionResult.self, from: data)
            if let b = result.fromBalance { applyBalance(for: from, value: b) }
            if let b = result.toBalance   { applyBalance(for: to,   value: b) }
        } catch {
            actionError = error.localizedDescription
        }
        actionLoading = false
    }

    // MARK: - Loan

    func payLoan(amount: Double) async {
        guard let ids = accountIDs else { return }
        actionLoading = true
        actionError   = nil

        guard let url = URL(string: "\(baseURL)/api/actions/pay-loan") else { actionLoading = false; return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["checking_id": ids.checkingId, "loan_id": ids.loanId, "amount": amount]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            let result = try decoder.decode(ActionResult.self, from: data)
            if let b = result.checking { checkingBalance = b }
            if let b = result.loan     { loanBalance     = b }
        } catch {
            actionError = error.localizedDescription
        }
        actionLoading = false
    }

    func takeLoan(amount: Double) async {
        guard let ids = accountIDs else { return }
        actionLoading = true
        actionError   = nil

        guard let url = URL(string: "\(baseURL)/api/actions/take-loan") else { actionLoading = false; return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["checking_id": ids.checkingId, "loan_id": ids.loanId, "amount": amount]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            let result = try decoder.decode(ActionResult.self, from: data)
            if let b = result.checking { checkingBalance = b }
            if let b = result.loan     { loanBalance     = b }
        } catch {
            actionError = error.localizedDescription
        }
        actionLoading = false
    }

    // MARK: - Shop

    func buyInventory(amount: Double) async {
        guard let ids = accountIDs, let mids = merchantIDs else { return }
        actionLoading = true
        actionError   = nil

        guard let url = URL(string: "\(baseURL)/api/actions/buy-inventory") else { actionLoading = false; return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "checking_id":        ids.checkingId,
            "supply_merchant_id": mids.supplyMerchantId,
            "amount":             amount
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            let result = try decoder.decode(ActionResult.self, from: data)
            if let b = result.checking { checkingBalance = b }
            inventoryValue += amount
        } catch {
            actionError = error.localizedDescription
        }
        actionLoading = false
    }

    func upgradeEquipment(amount: Double) async {
        guard let ids = accountIDs, let mids = merchantIDs else { return }
        actionLoading = true
        actionError   = nil

        guard let url = URL(string: "\(baseURL)/api/actions/upgrade-equipment") else { actionLoading = false; return }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "checking_id":           ids.checkingId,
            "equipment_merchant_id": mids.equipmentMerchantId,
            "amount":                amount
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            let result = try decoder.decode(ActionResult.self, from: data)
            if let b = result.checking { checkingBalance = b }
            equipmentValue += amount
        } catch {
            actionError = error.localizedDescription
        }
        actionLoading = false
    }

    // MARK: - Ledger

    func fetchLedger() async -> LedgerData? {
        guard let ids = accountIDs else { return nil }
        var components = URLComponents(string: "\(baseURL)/api/ledger")
        components?.queryItems = [
            URLQueryItem(name: "checking_id",   value: ids.checkingId),
            URLQueryItem(name: "savings_id",    value: ids.savingsId),
            URLQueryItem(name: "investment_id", value: ids.investmentId),
            URLQueryItem(name: "loan_id",       value: ids.loanId),
        ]
        guard let url = components?.url else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            try validateResponse(response)
            return try decoder.decode(LedgerData.self, from: data)
        } catch {
            return nil
        }
    }
}