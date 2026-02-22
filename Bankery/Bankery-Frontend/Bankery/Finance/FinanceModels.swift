import Foundation

// MARK: - Init Response  (POST /api/game/init)

struct InitResponse: Decodable {
    let accounts: AccountIDs
    let merchants: MerchantIDs
    let startingBalances: StartingBalances
    let message: String
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
}

struct MerchantIDs: Codable {
    let supplyMerchantId: String
    let equipmentMerchantId: String
    let utilityMerchantId: String
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
        case type, message        // id is excluded so Decodable doesn't expect it in JSON
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
    let message:     String?
    let error:       String?
    let checking:    Double?
    let savings:     Double?
    let investment:  Double?
    let loan:        Double?
    let fromBalance: Double?
    let toBalance:   Double?
}

// MARK: - Ledger  (GET /api/ledger)

struct NessieTransaction: Decodable, Identifiable {
    let id:              String
    let status:          String?

    // Regular transactions use "amount"; bills use "payment_amount"
    private let _amount:        Double?
    private let _paymentAmount: Double?
    var amount: Double { _amount ?? _paymentAmount ?? 0 }

    // Regular transactions use "description"; bills use "payee"
    private let _description: String?
    private let _payee:       String?
    var description: String? { _description ?? _payee }

    // Regular transactions use "transaction_date"; bills use "payment_date"
    private let _transactionDate: String?
    private let _paymentDate:     String?
    var transactionDate: String? { _transactionDate ?? _paymentDate }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status
        case _amount          = "amount"
        case _paymentAmount   = "payment_amount"
        case _description     = "description"
        case _payee           = "payee"
        case _transactionDate = "transaction_date"
        case _paymentDate     = "payment_date"
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

// MARK: - Eclair Gemini Reflection  (POST /api/eclair/reflect)

struct EclairReflectRequest: Encodable {
    let actionsSummary: [String]
    let checking:       Double
    let savings:        Double
    let loan:           Double
    let week:           Int
}

struct EclairReflectResponse: Decodable {
    let reflection: String
}

// MARK: - Investments  (GET /api/investments/top)

struct TopTicker: Decodable, Identifiable {
    let symbol:         String
    let price:          Double
    let dailyChangePct: Double
    var id: String { symbol }
}

struct TopInvestmentsResponse: Decodable {
    let tickers: [TopTicker]
}

// MARK: - Event Request / Response  (POST /api/events/*)

struct EventRequest: Encodable {
    let choiceIndex: Int
    let checkingId:  String
    let savingsId:   String
    let loanId:      String
}

struct EventResult: Decodable {
    let message:   String
    let checking:  Double?
    let savings:   Double?
    let loan:      Double?
    let alertType: String?    // "success" | "warning" | "info"
}

