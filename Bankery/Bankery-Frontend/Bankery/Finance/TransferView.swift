//
//  TransferView.swift
//  Bankery
//

import SwiftUI

struct TransferView: View {
    @Environment(FinanceViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var fromAccount: AccountType = .checking
    @State private var toAccount:   AccountType = .savings
    @State private var amountText:  String      = ""
    @State private var didSucceed:  Bool        = false

    // Eclair panel
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil
    private let eclairLines: [(text: String, pose: String)] = [
        (text: "Move money between your accounts here.", pose: "stand_speak"),
        (text: "Keep Checking healthy — bills come out of there!", pose: "stand_worried"),
        (text: "Savings earns a little interest every week — let it grow!", pose: "stand_speak_armsout"),
    ]
    @State private var eclairIndex: Int = 0

    private var amount: Double { Double(amountText) ?? 0 }

    private var sourceBalance: Double {
        switch fromAccount {
        case .checking:   return vm.checkingBalance
        case .savings:    return vm.savingsBalance
        case .investment: return vm.investmentBalance
        }
    }

    private var validationError: String? {
        if fromAccount == toAccount { return "From and To accounts must be different." }
        if amount <= 0              { return "Enter an amount greater than $0." }
        if amount > sourceBalance   { return "Not enough funds in \(fromAccount.rawValue)." }
        return nil
    }

    private var canTransfer: Bool { validationError == nil && !vm.actionLoading }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("Computer_overlay")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Back button + title ──
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
                            Text("Transfer Funds")
                                .font(.custom("Cute-Dino", size: 28))
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .opacity(0)
                        }

                        // ── Balance Cards ──
                        HStack(spacing: 0) {
                            balanceCell("Checking",   amount: vm.checkingBalance,   color: .blue)
                            Divider()
                            balanceCell("Savings",    amount: vm.savingsBalance,    color: .green)
                            Divider()
                            balanceCell("Investment", amount: vm.investmentBalance, color: .purple)
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)

                        // ── From / To Pickers ──
                        accountPicker(label: "From", selection: $fromAccount)
                        accountPicker(label: "To",   selection: $toAccount)

                        // ── Amount ──
                        amountField

                        // ── Feedback ──
                        if let err = vm.actionError {
                            feedbackBanner(err, isError: true)
                        } else if let err = validationError, !amountText.isEmpty {
                            feedbackBanner(err, isError: true)
                        }
                        if didSucceed {
                            feedbackBanner("Transfer complete!", isError: false)
                        }

                        // ── Confirm Button ──
                        Button {
                            Task {
                                await vm.transfer(from: fromAccount, to: toAccount, amount: amount)
                                if vm.actionError == nil {
                                    didSucceed = true
                                    amountText = ""
                                    try? await Task.sleep(nanoseconds: 800_000_000)
                                    dismiss()
                                }
                            }
                        } label: {
                            Group {
                                if vm.actionLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Transfer \(formatted(amount))")
                                        .font(.custom("Cute-Dino", size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Rectangle().fill(
                                canTransfer
                                    ? Color(red: 54/255, green: 54/255, blue: 54/255)
                                    : Color(red: 54/255, green: 54/255, blue: 54/255).opacity(0.4)
                            ))
                        }
                        .disabled(!canTransfer)
                    }
                    .padding(.horizontal, 142)
                    .padding(.top, 120)
                    .padding(.bottom, geo.size.height * 0.28)
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
                                    .font(.custom("Cute-Dino", size: 42))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text(displayedText)
                                    .font(.custom("Cute-Dino", size: 32))
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

    private func balanceCell(_ label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("Cute-Dino", size: 14))
                .foregroundColor(.secondary)
            Text(formatted(amount))
                .font(.custom("Cute-Dino", size: 17))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private func accountPicker(label: String, selection: Binding<AccountType>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.custom("Cute-Dino", size: 16))
                .foregroundColor(.secondary)
            HStack(spacing: 0) {
                ForEach(AccountType.allCases) { type in
                    Button { selection.wrappedValue = type } label: {
                        Text(type.rawValue)
                            .font(.custom("Cute-Dino", size: 16))
                            .foregroundColor(selection.wrappedValue == type ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selection.wrappedValue == type
                                    ? Color(red: 54/255, green: 54/255, blue: 54/255)
                                    : Color(.secondarySystemBackground)
                            )
                    }
                }
            }
            .cornerRadius(14)
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Amount")
                .font(.custom("Cute-Dino", size: 16))
                .foregroundColor(.secondary)
            HStack {
                Text("$")
                    .font(.custom("Cute-Dino", size: 24))
                    .foregroundColor(.secondary)
                TextField("0.00", text: $amountText)
                    .font(.custom("Cute-Dino", size: 24))
                    .foregroundColor(.primary)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
        }
    }

    private func feedbackBanner(_ message: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .orange : .green)
            Text(message)
                .font(.custom("Cute-Dino", size: 18))
                .foregroundColor(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }

    private func formatted(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle  = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack { TransferView().environment(FinanceViewModel()) }
}
