//
//  LoanView.swift
//  Bankery
//

import SwiftUI

private enum LoanMode: String, CaseIterable, Identifiable {
    case pay = "Pay Down"
    case borrow = "Borrow More"
    var id: String {
        rawValue
    }
}

struct LoanView: View {
    @Environment(FinanceViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var mode: LoanMode = .pay
    @State private var amountText: String = ""
    @State private var didSucceed: Bool = false

    // Eclair panel
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil
    private let eclairLines: [(text: String, pose: String)] = [
        (text: "The loan is what we borrowed to open Bankery. Let's pay it off!", pose: "stand_speak"),
        (text: "Every week, interest is charged on the outstanding balance.", pose: "stand_worried"),
        (text: "You can also borrow more cash if you need it — but it costs you!", pose: "stand_speak_armsout"),
    ]
    @State private var eclairIndex: Int = 0

    private var amount: Double {
        Double(amountText) ?? 0
    }

    private var validationError: String? {
        guard !amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil // Don't show error for empty field
        }
        if amount <= 0 { return "Enter a valid amount greater than $0." }
        if mode == .pay {
            if amount > vm.checkingBalance { return "Not enough funds in Checking (\(formatted(vm.checkingBalance)) available)." }
            if amount > vm.loanBalance { return "Amount exceeds current loan balance (\(formatted(vm.loanBalance)))." }
        } else {
            if amount > 50_000 { return "Loan amount cannot exceed $50,000." }
        }
        return nil
    }

    private var canConfirm: Bool {
        validationError == nil &&
            !vm.actionLoading &&
            amount > 0 &&
            !amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                            Text("Loan Management")
                                .font(.custom("Cute-Dino", size: 28))
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .opacity(0)
                        }

                        // ── Loan Status Card ──
                        loanStatusCard

                        // ── Mode Picker ──
                        modePicker

                        // ── Context text ──
                        Text(mode == .pay
                            ? "Paying down the loan reduces your debt and saves on weekly interest charges."
                            : "Taking more debt adds cash to Checking but increases your weekly interest payments.")
                            .font(.custom("Cute-Dino", size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // ── Amount ──
                        amountField

                        // ── Feedback ──
                        if let err = vm.actionError {
                            feedbackBanner(err, isError: true)
                        } else if let err = validationError, !amountText.isEmpty {
                            feedbackBanner(err, isError: true)
                        }
                        if didSucceed {
                            feedbackBanner(
                                mode == .pay ? "Loan payment made!" : "Funds added to Checking.",
                                isError: false
                            )
                        }

                        // ── Confirm Button ──
                        Button {
                            Task {
                                if mode == .pay {
                                    await vm.payLoan(amount: amount)
                                } else {
                                    await vm.takeLoan(amount: amount)
                                }
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
                                    Text(mode == .pay ? "Pay \(formatted(amount))" : "Borrow \(formatted(amount))")
                                        .font(.custom("Cute-Dino", size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Rectangle().fill(
                                canConfirm
                                    ? (mode == .pay ? Color.green : Color.orange)
                                    : Color(red: 54/255, green: 54/255, blue: 54/255)
                            ))
                        }
                        .disabled(!canConfirm)
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

    private var loanStatusCard: some View {
        HStack(spacing: 0) {
            statCell(label: "Loan Balance", value: vm.loanBalance, color: .red)
            Divider()
            statCell(label: "Checking", value: vm.checkingBalance, color: .blue)
            Divider()
            statCell(label: "Net Worth", value: vm.netWorth, color: vm.netWorth >= 0 ? .green : .red)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private func statCell(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("Cute-Dino", size: 14))
                .foregroundColor(.secondary)
            Text(formatted(value))
                .font(.custom("Cute-Dino", size: 17))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(LoanMode.allCases) { m in
                Button { withAnimation(.easeInOut(duration: 0.2)) { mode = m } } label: {
                    Text(m.rawValue)
                        .font(.custom("Cute-Dino", size: 18))
                        .foregroundColor(mode == m ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            mode == m
                                ? (m == .pay ? Color.green : Color.orange)
                                : Color(.secondarySystemBackground)
                        )
                }
            }
        }
        .cornerRadius(14)
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
                    .onChange(of: amountText) { _, newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            amountText = filtered
                        }
                    }
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
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack { LoanView().environment(FinanceViewModel()) }
}
