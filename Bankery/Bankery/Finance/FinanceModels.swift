//
//  FinanceModels.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import Foundation

// MARK: - API Response Models

struct InitResponse: Decodable {
    let customerId: String
    let accounts: AccountIDs
    let message: String

    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case accounts
        case message
    }
}

struct AccountIDs: Decodable {
    let checkingId: String
    let savingsId: String
    let loanId: String

    enum CodingKeys: String, CodingKey {
        case checkingId = "checking_id"
        case savingsId  = "savings_id"
        case loanId     = "loan_id"
    }
}

struct NextMonthResponse: Decodable {
    let balances: Balances
    let alerts: [GameAlert]
}

struct Balances: Decodable {
    let checking: Double
    let savings: Double
    let loan: Double
}

struct GameAlert: Decodable, Identifiable {
    let id = UUID()
    let type: String      // "success" or "danger"
    let message: String

    enum CodingKeys: String, CodingKey {
        case type
        case message
    }
}

// MARK: - Balance Sheet Row

struct BalanceSheetRow: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let color: String   // "blue", "green", "orange", "purple", "yellow", "red"
}

// MARK: - Game State

enum GameOutcome {
    case ongoing
    case won
    case lost
}
