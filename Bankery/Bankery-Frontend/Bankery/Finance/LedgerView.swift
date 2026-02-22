//
//  LedgerView.swift
//  Bankery
//

import SwiftUI

private enum LedgerAccount: String, CaseIterable, Identifiable {
    case checking   = "Checking"
    case savings    = "Savings"
    case investment = "Investment"
    case loan       = "Loan"
    var id: String { rawValue }
}

struct LedgerView: View {
    @Environment(FinanceViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAccount: LedgerAccount = .checking
    @State private var ledger:          LedgerData?   = nil
    @State private var isLoading:       Bool          = false
    @State private var loadError:       String?       = nil

    // Eclair panel
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil
    private let eclairLines: [(text: String, pose: String)] = [
        (text: "Here's a full record of every transaction in each account.", pose: "stand_speak_armsout"),
        (text: "Green means money coming in. Red means money going out.", pose: "stand_speak"),
        (text: "Keeping tabs on history helps you spot patterns and plan ahead!", pose: "stand_speak"),
    ]
    @State private var eclairIndex: Int = 0

    private var currentTransactions: [NessieTransaction] {
        guard let l = ledger else { return [] }
        let txns: [NessieTransaction]
        switch selectedAccount {
        case .checking:   txns = l.checking.allTransactions
        case .savings:    txns = l.savings.allTransactions
        case .investment: txns = l.investment.allTransactions
        case .loan:       txns = l.loan.allTransactions
        }
        return txns.sorted { ($0.transactionDate ?? "") > ($1.transactionDate ?? "") }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("Computer_overlay")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Back + title + tabs ──
                    VStack(spacing: 16) {
                        HStack {
                            Button { dismiss() } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.custom("Cute-Dino", size: 18))
                                .foregroundColor(.primary)
                            }
                            Spacer()
                            Text("Transaction History")
                                .font(.custom("Cute-Dino", size: 28))
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .opacity(0)
                        }

                        accountTabs
                    }
                    .padding(.horizontal, 142)
                    .padding(.top, 120)

                    // ── Transaction List ──
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.primary)
                            .scaleEffect(1.4)
                        Spacer()
                    } else if let error = loadError {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "wifi.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text(error)
                                .font(.custom("Cute-Dino", size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else if currentTransactions.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No transactions yet.")
                                .font(.custom("Cute-Dino", size: 18))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(currentTransactions) { tx in
                                    transactionRow(tx)
                                }
                            }
                            .padding(.horizontal, 142)
                            .padding(.top, 16)
                            .padding(.bottom, geo.size.height * 0.28)
                        }
                    }
                }

                // ── Dialogue Panel (bottom 1/4) ──
                VStack {
                    Spacer()
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 54/255, green: 54/255, blue: 54/255))
                            .ignoresSafeArea(edges: .bottom)

                        HStack(alignment: .top, spacing: 16) {
                            Image(eclairLines[eclairIndex].pose)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 94, height: 94)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                                .padding(.top, 16)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Eclair")
                                    .font(.custom("Cute-Dino", size: 35))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text(displayedText)
                                    .font(.custom("Cute-Dino", size: 25))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                            .padding(.top, 30)
                            Spacer()
                        }
                        .padding(.horizontal, 30)

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(isTyping ? "Tap to skip..." : (eclairIndex < eclairLines.count - 1 ? "Tap to continue →" : ""))
                                    .font(.custom("Cute-Dino", size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.trailing, 20)
                            }
                            .padding(.bottom, 12)
                        }
                    }
                    .frame(height: geo.size.height * 0.25)
                    .padding(.horizontal, 120)
                    .padding(.bottom, 40)
                    .contentShape(Rectangle())
                    .onTapGesture { handleEclairTap() }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear { startTyping(eclairLines[0].text) }
        .task { await loadLedger() }
    }

    // MARK: - Eclair helpers
    private func startTyping(_ text: String) {
        typingTask?.cancel()
        displayedText = ""
        isTyping = true
        typingTask = Task {
            for char in text {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 35_000_000)
                if Task.isCancelled { break }
                displayedText.append(char)
            }
            isTyping = false
        }
    }
    private func handleEclairTap() {
        if isTyping {
            typingTask?.cancel()
            displayedText = eclairLines[eclairIndex].text
            isTyping = false
        } else if eclairIndex < eclairLines.count - 1 {
            eclairIndex += 1
            startTyping(eclairLines[eclairIndex].text)
        }
    }

    // MARK: - Sub-views

    private var accountTabs: some View {
        HStack(spacing: 0) {
            ForEach(LedgerAccount.allCases) { account in
                Button { selectedAccount = account } label: {
                    Text(account.rawValue)
                        .font(.custom("Cute-Dino", size: 15))
                        .foregroundColor(selectedAccount == account ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedAccount == account
                                ? Color(red: 54/255, green: 54/255, blue: 54/255)
                                : Color(.secondarySystemBackground)
                        )
                }
            }
        }
        .cornerRadius(14)
    }

    private func transactionRow(_ tx: NessieTransaction) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(amountColor(tx.amount).opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: tx.amount >= 0 ? "arrow.down.left" : "arrow.up.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(amountColor(tx.amount))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.description ?? "Transaction")
                    .font(.custom("Cute-Dino", size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let date = tx.transactionDate {
                    Text(date)
                        .font(.custom("Cute-Dino", size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(formatted(tx.amount))
                .font(.custom("Cute-Dino", size: 17))
                .fontWeight(.semibold)
                .foregroundColor(amountColor(tx.amount))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Helpers

    private func amountColor(_ amount: Double) -> Color {
        amount >= 0 ? .green : .red
    }

    private func formatted(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle  = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func loadLedger() async {
        isLoading = true
        loadError = nil
        let result = await vm.fetchLedger()
        if let result {
            ledger = result
        } else {
            loadError = "Couldn't load transactions.\nMake sure the backend is running."
        }
        isLoading = false
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack { LedgerView().environment(FinanceViewModel()) }
}
