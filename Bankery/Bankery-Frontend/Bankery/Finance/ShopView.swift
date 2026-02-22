//
//  ShopView.swift
//  Bankery
//

import SwiftUI

struct ShopView: View {
    @Environment(FinanceViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var inventoryAmountText: String = ""
    @State private var equipmentAmountText: String = ""
    @State private var inventorySuccess:    Bool   = false
    @State private var equipmentSuccess:    Bool   = false

    // Eclair panel
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil
    private let eclairLines: [(text: String, pose: String)] = [
        (text: "Stock up on supplies and equipment to keep Bankery running!", pose: "stand_speak_armsout"),
        (text: "Inventory is what we sell. Running out means no revenue!", pose: "stand_worried"),
        (text: "Equipment holds its value and helps us work more efficiently.", pose: "stand_speak"),
    ]
    @State private var eclairIndex: Int = 0

    private var inventoryAmount: Double { Double(inventoryAmountText) ?? 0 }
    private var equipmentAmount: Double { Double(equipmentAmountText) ?? 0 }

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
                            Text("Bakery Shop")
                                .font(.custom("Cute-Dino", size: 28))
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .opacity(0)
                        }

                        // ── Checking balance ──
                        HStack {
                            Text("Available in Checking")
                                .font(.custom("Cute-Dino", size: 16))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatted(vm.checkingBalance))
                                .font(.custom("Cute-Dino", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)

                        // ── Inventory Card ──
                        shopCard(
                            icon:         "basket.fill",
                            title:        "Buy Inventory",
                            subtitle:     "Purchase bakery supplies from Baker's Supply Co.",
                            currentLabel: "Current Inventory Value",
                            currentValue: vm.inventoryValue,
                            valueColor:   .orange,
                            amountText:   $inventoryAmountText,
                            success:      inventorySuccess,
                            error:        inventoryAmount > 0 && inventoryAmount > vm.checkingBalance
                                              ? "Not enough funds in Checking." : nil,
                            buttonLabel:  "Buy Supplies",
                            buttonColor:  .orange
                        ) {
                            Task {
                                await vm.buyInventory(amount: inventoryAmount)
                                if vm.actionError == nil {
                                    inventorySuccess    = true
                                    inventoryAmountText = ""
                                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                                    inventorySuccess    = false
                                }
                            }
                        }

                        // ── Equipment Card ──
                        shopCard(
                            icon:         "wrench.and.screwdriver.fill",
                            title:        "Upgrade Equipment",
                            subtitle:     "Invest in ovens, mixers, and tools that hold their value.",
                            currentLabel: "Current Equipment Value",
                            currentValue: vm.equipmentValue,
                            valueColor:   Color(red: 0.85, green: 0.72, blue: 0),
                            amountText:   $equipmentAmountText,
                            success:      equipmentSuccess,
                            error:        equipmentAmount > 0 && equipmentAmount > vm.checkingBalance
                                              ? "Not enough funds in Checking." : nil,
                            buttonLabel:  "Buy Equipment",
                            buttonColor:  Color(red: 0.85, green: 0.72, blue: 0)
                        ) {
                            Task {
                                await vm.upgradeEquipment(amount: equipmentAmount)
                                if vm.actionError == nil {
                                    equipmentSuccess    = true
                                    equipmentAmountText = ""
                                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                                    equipmentSuccess    = false
                                }
                            }
                        }

                        if let err = vm.actionError {
                            feedbackBanner(err, isError: true)
                        }
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

    // MARK: - Shop Card

    private func shopCard(
        icon:         String,
        title:        String,
        subtitle:     String,
        currentLabel: String,
        currentValue: Double,
        valueColor:   Color,
        amountText:   Binding<String>,
        success:      Bool,
        error:        String?,
        buttonLabel:  String,
        buttonColor:  Color,
        onBuy:        @escaping () -> Void
    ) -> some View {
        let amount = Double(amountText.wrappedValue) ?? 0
        let canBuy = amount > 0 && amount <= vm.checkingBalance && !vm.actionLoading

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(valueColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Cute-Dino", size: 20))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.custom("Cute-Dino", size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Text(currentLabel)
                    .font(.custom("Cute-Dino", size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatted(currentValue))
                    .font(.custom("Cute-Dino", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(valueColor)
            }

            HStack {
                Text("$")
                    .font(.custom("Cute-Dino", size: 24))
                    .foregroundColor(.secondary)
                TextField("0.00", text: amountText)
                    .font(.custom("Cute-Dino", size: 24))
                    .foregroundColor(.primary)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)

            if success {
                feedbackBanner("Purchase successful!", isError: false)
            } else if let err = error {
                feedbackBanner(err, isError: true)
            }

            Button(action: onBuy) {
                Group {
                    if vm.actionLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(buttonLabel)
                            .font(.custom("Cute-Dino", size: 18))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Rectangle().fill(canBuy ? buttonColor : Color(red: 54/255, green: 54/255, blue: 54/255)))
            }
            .disabled(!canBuy)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Feedback

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
    NavigationStack { ShopView().environment(FinanceViewModel()) }
}
