//
//  FinanceModels.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import Foundation

// MARK: - Init Response  (POST /api/game/init)

struct InitResponse: Decodable {
    let accounts: AccountIDs
    let merchants: MerchantIDs
    let startingBalances: StartingBalances
    let message: String

    enum CodingKeys: String, CodingKey {
        case accounts
        case merchants
        case startingBalances = "starting_balances"
        case message
    }
}

struct StartingBalances: Decodable {
    let checking: Double
    let savings: Double
    let investment: Double
    let loan: Double
}

// MARK: - Account & Merchant ID Bundles
// Both Encodable + Decodable — decoded from init response, encoded into every subsequent request.

struct AccountIDs: Codable {
    let checkingId: String
    let savingsId: String
    let investmentId: String
    let loanId: String

    enum CodingKeys: String, CodingKey {
        case checkingId   = "checking_id"
        case savingsId    = "savings_id"
        case investmentId = "investment_id"
        case loanId       = "loan_id"
    }
}

struct MerchantIDs: Codable {
    let supplyMerchantId: String
    let equipmentMerchantId: String
    let utilityMerchantId: String

    enum CodingKeys: String, CodingKey {
        case supplyMerchantId    = "supply_merchant_id"
        case equipmentMerchantId = "equipment_merchant_id"
        case utilityMerchantId   = "utility_merchant_id"
    }
}

// MARK: - Next Week Request  (POST /api/game/next-week)

struct NextWeekRequest: Encodable {
    let accounts: AccountIDs
    let merchants: MerchantIDs
    let week: Int
    let inventory: Double
    let equipment: Double
}

// MARK: - Week Result  (response from /api/game/next-week)

struct WeekResult: Decodable {
    let week: Int
    let revenue: Double
    let fixedExpenses: Double
    let balances: WeekBalances
    let netWorth: Double
    let inventory: Double
    let equipment: Double
    let gameOutcome: String         // "ongoing" | "won" | "lost"
    let alerts: [GameAlert]

    enum CodingKeys: String, CodingKey {
        case week, revenue, balances, inventory, equipment, alerts
        case fixedExpenses = "fixed_expenses"
        case netWorth      = "net_worth"
        case gameOutcome   = "game_outcome"
    }
}

struct WeekBalances: Decodable {
    let checking: Double
    let savings: Double
    let investment: Double
    let loan: Double
}

// MARK: - Alert

struct GameAlert: Decodable, Identifiable {
    let id    = UUID()
    let type: String      // "success" | "warning" | "danger" | "info"
    let message: String

    enum CodingKeys: String, CodingKey {
        case type, message
    }
}

// MARK: - Balance Sheet Row  (UI helper)

struct BalanceSheetRow: Identifiable {
    let id     = UUID()
    let label: String
    let amount: Double
    let color: String    // "blue" | "green" | "purple" | "orange" | "yellow" | "red"
}

// MARK: - Game Outcome

enum GameOutcome {
    case ongoing, won, lost
}

// MARK: - Account Type (used by TransferView picker)

enum AccountType: String, CaseIterable, Identifiable {
    case checking   = "Checking"
    case savings    = "Savings"
    case investment = "Investment"
    var id: String { rawValue }
}

// MARK: - Action Result (response from POST /api/actions/*)

struct ActionResult: Decodable {
    let message:     String
    let checking:    Double?
    let savings:     Double?
    let investment:  Double?
    let loan:        Double?
    let fromBalance: Double?
    let toBalance:   Double?

    enum CodingKeys: String, CodingKey {
        case message, checking, savings, investment, loan
        case fromBalance = "from_balance"
        case toBalance   = "to_balance"
    }
}

// MARK: - Ledger  (GET /api/ledger)

struct NessieTransaction: Decodable, Identifiable {
    let id:              String
    let amount:          Double
    let description:     String?
    let status:          String?
    let transactionDate: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case amount, description, status
        case transactionDate = "transaction_date"
    }
}

struct AccountLedger: Decodable {
    let deposits:    [NessieTransaction]?
    let withdrawals: [NessieTransaction]?
    let transfers:   [NessieTransaction]?
    let purchases:   [NessieTransaction]?
    let bills:       [NessieTransaction]?

    var allTransactions: [NessieTransaction] {
        let d = deposits    ?? []
        let w = withdrawals ?? []
        let t = transfers   ?? []
        let p = purchases   ?? []
        let b = bills       ?? []
        return d + w + t + p + b
    }
}

struct LedgerData: Decodable {
    let checking:   AccountLedger
    let savings:    AccountLedger
    let investment: AccountLedger
    let loan:       AccountLedger
}

