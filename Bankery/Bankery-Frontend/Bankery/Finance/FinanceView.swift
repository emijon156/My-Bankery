//
//  FinanceView.swift
//  Bankery
//

import SwiftUI

struct FinanceView: View {
    let stage: Int
    @Environment(FinanceViewModel.self) private var financeViewModel
    @State private var dialogueViewModel = DialogueViewModel()
    @State private var goToNextDialogue  = false

    // Typewriter
    @State private var displayedText: String = ""
    @State private var isTyping: Bool  = false
    @State private var typingTask: Task<Void, Never>? = nil
    @State private var dialogueDone: Bool = false
    @State private var hasAppeared: Bool = false

    // Action sheets
    @State private var showTransfer:     Bool = false
    @State private var showLoan:         Bool = false
    //@State private var showShop:         Bool = false
    @State private var showLedger:       Bool = false
    @State private var showInvestments:  Bool = false

    // Ask Eclair
    @State private var showEclairSheet:      Bool   = false
    @State private var eclairReflecting:     Bool   = false
    @State private var eclairReflectionText: String = ""

    // Scroll tracking
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 600

    init(stage: Int = 0) { self.stage = stage }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("Computer_overlay")
                    .resizable()
                    //.scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    //.clipped()
                    .ignoresSafeArea()

                if financeViewModel.outcome == .lost {
                    outcomeScreen(title: "Game Over 💸",
                                  subtitle: "Your checking account ran out of money.", won: false)
                } else if financeViewModel.outcome == .won {
                    outcomeScreen(title: "You Won! 🎉",
                                  subtitle: "You paid off the loan. Bankery is saved!", won: true)
                } else {
                    // ── Main content ──
                    HStack(alignment: .top, spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 20) {

                            // Net Worth banner
                            VStack(spacing: 4) {
                                Text("Net Worth")
                                    .font(.custom("Cute-Dino", size: 18))
                                    .foregroundColor(.secondary)
                                Text(formatted(financeViewModel.netWorth))
                                    .font(.custom("Cute-Dino", size: 36))
                                    .foregroundColor(financeViewModel.netWorth >= 0 ? .green : .red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))

                            // Balance Sheet — two columns
                            HStack(alignment: .top, spacing: 16) {

                                // ASSETS column
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Assets")
                                        .font(.custom("Cute-Dino", size: 20))
                                        .foregroundColor(.primary)
                                        .padding(.bottom, 2)

                                    Text("Cash")
                                        .font(.custom("Cute-Dino", size: 14))
                                        .foregroundColor(.secondary)

                                    ForEach(financeViewModel.assetRows.filter {
                                        $0.label == "Checking" || $0.label == "Savings"
                                    }) { row in
                                        balanceRow(row)
                                    }

                                    Divider().padding(.vertical, 4)

                                    ForEach(financeViewModel.assetRows.filter {
                                        $0.label != "Checking" && $0.label != "Savings"
                                    }) { row in
                                        balanceRow(row)
                                    }

                                    Divider().padding(.vertical, 4)

                                    HStack {
                                        Text("Total Assets")
                                            .font(.custom("Cute-Dino", size: 15))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formatted(financeViewModel.totalAssets))
                                            .font(.custom("Cute-Dino", size: 16))
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)

                                // LIABILITIES column
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Liabilities")
                                        .font(.custom("Cute-Dino", size: 20))
                                        .foregroundColor(.primary)
                                        .padding(.bottom, 2)

                                    ForEach(financeViewModel.liabilityRows) { row in
                                        balanceRow(row)
                                    }

                                    Divider().padding(.vertical, 4)

                                    HStack {
                                        Text("Total Liabilities")
                                            .font(.custom("Cute-Dino", size: 15))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formatted(financeViewModel.totalLiabilities))
                                            .font(.custom("Cute-Dino", size: 16))
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)
                            }
                            .padding(.horizontal)

                            // Alerts
                            if !financeViewModel.alerts.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Alerts")
                                        .font(.custom("Cute-Dino", size: 20))
                                        .padding(.horizontal)

                                    ForEach(financeViewModel.alerts) { alert in
                                        HStack(spacing: 10) {
                                            Image(systemName: alert.type == "success"
                                                  ? "checkmark.circle.fill"
                                                  : "exclamationmark.triangle.fill")
                                                .foregroundColor(alert.type == "success" ? .green : .orange)
                                            Text(alert.message)
                                                .font(.custom("Cute-Dino", size: 18))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            // Error
                            if let error = financeViewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }

                            // Action buttons — always visible
                            HStack(spacing: 10) {
                                actionButton("Transfer")   { showTransfer = true }
                                actionButton("Loan") { showLoan     = true }
                                //actionButton("Shop",     icon: "cart.fill",              color: .green)  { showShop     = true }
                                actionButton("History") { showLedger   = true }
                            }
                            .padding(.horizontal)

                            // Investments button — unlocked at Stage 4
                            if stage >= 4 {
                                Button(action: { showInvestments = true }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.title2)
                                        Text("Investments")
                                            .font(.custom("Cute-Dino", size: 22))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.07, green: 0.45, blue: 0.26),
                                                     Color(red: 0.12, green: 0.60, blue: 0.38)],
                                            startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(14)
                                }
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // Next Week button — unlocked after all dialogue
                            if dialogueDone {
                                // Ask Eclair button
                                Button(action: {
                                    let actions = financeViewModel.sessionActions
                                    showEclairSheet  = true
                                    eclairReflecting = true
                                    eclairReflectionText = ""
                                    Task {
                                        let text = await financeViewModel.askEclair(actions: actions)
                                        eclairReflecting     = false
                                        eclairReflectionText = text
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Text("Ask Eclair")
                                            .font(.custom("Cute-Dino", size: 22))
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        Capsule()
                                            .fill(Color(red: 0.45, green: 0.22, blue: 0.60))
                                    )
                                }
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                                Button(action: {
                                    Task {
                                        await financeViewModel.nextWeek()
                                        goToNextDialogue = true
                                    }
                                }) {
                                    Group {
                                        if financeViewModel.isLoading {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Next Week →")
                                                .font(.custom("Cute-Dino", size: 24))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Rectangle()
                                        .fill(Color(red: 54/255, green: 54/255, blue: 54/255)))
                                }
                                .disabled(financeViewModel.isLoading)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.horizontal, 142)
                        //.padding(.top, 120)
                        .padding(.bottom, geo.size.height * 0.28)
                        .animation(.easeInOut, value: dialogueDone)
                        .background(
                            GeometryReader { inner in
                                Color.clear
                                    .onAppear { contentHeight = inner.size.height }
                                    .onChange(of: inner.size.height) { _, h in contentHeight = h }
                                    .preference(key: ScrollOffsetKey.self,
                                                value: inner.frame(in: .named("scrollArea")).minY)
                            }
                        )
                        .onPreferenceChange(ScrollOffsetKey.self) { val in
                            scrollOffset = -val
                        }
                    }
                    } // end HStack
                    .coordinateSpace(name: "scrollArea")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 100)
                    .padding(.bottom, 160)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        ScrollIndicatorView(
                            contentHeight: contentHeight,
                            scrollOffset: scrollOffset,
                            availableHeight: geo.size.height - 100 - 160
                        )
                        .frame(width: 6)
                        .padding(.top, 100)
                        .padding(.bottom, 160)
                        .padding(.trailing, 80)
                    }

                    // ── Dialogue Panel (bottom 1/4) ──
                    VStack {
                        Spacer()

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(red: 54/255, green: 54/255, blue: 54/255))
                                .ignoresSafeArea(edges: .bottom)

                            HStack(alignment: .top, spacing: 16) {
                                Image(dialogueViewModel.currentLine.poseImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 94, height: 94)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                                    .padding(.top, 16)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dialogueViewModel.currentLine.speaker)
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
                                    HStack(spacing: 6) {
                                        ForEach(0..<dialogueViewModel.lines.count, id: \.self) { i in
                                            Circle()
                                                .fill(i == dialogueViewModel.currentIndex
                                                      ? Color.white : Color.white.opacity(0.35))
                                                .frame(width: 6, height: 6)
                                                .animation(.easeInOut, value: dialogueViewModel.currentIndex)
                                        }
                                    }
                                    .padding(.leading, 20)

                                    Spacer()

                                    Text(isTyping ? "Tap to skip..."
                                         : (dialogueDone ? "" : "Tap to continue →"))
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
                        .onTapGesture { handleDialogueTap() }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToNextDialogue) {
            DialogueView(stage: stage + 1)
        }
        .navigationDestination(isPresented: $showTransfer) { TransferView().environment(financeViewModel) }
        .navigationDestination(isPresented: $showLoan)     { LoanView().environment(financeViewModel) }
        //.navigationDestination(isPresented: $showShop)     { ShopView().environment(financeViewModel) }
        .navigationDestination(isPresented: $showLedger)   { LedgerView().environment(financeViewModel) }
        .navigationDestination(isPresented: $showInvestments) { InvestmentView().environment(financeViewModel) }
        .sheet(isPresented: $showEclairSheet) {
            EclairReflectionSheet(
                isReflecting: eclairReflecting,
                reflectionText: eclairReflectionText
            )
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            dialogueViewModel.loadFinanceStage(stage)
            startTyping(dialogueViewModel.currentLine.text)
        }
        .onChange(of: dialogueViewModel.currentIndex) { _, _ in
            startTyping(dialogueViewModel.currentLine.text)
        }
    }

    // MARK: - Action Button

    private func actionButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(label)
                    .font(.custom("Cute-Dino", size: 13))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Balance Row

    private func balanceRow(_ row: BalanceSheetRow) -> some View {
        HStack {
            Text(row.label)
                .font(.custom("Cute-Dino", size: 16))
                .foregroundColor(.secondary)
            Spacer()
            Text(formatted(row.amount))
                .font(.custom("Cute-Dino", size: 17))
                .fontWeight(.semibold)
                .foregroundColor(rowColor(row.color))
        }
    }

    private func rowColor(_ name: String) -> Color {
        switch name {
        case "blue":   return .blue
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return Color(red: 0.85, green: 0.72, blue: 0)
        default:       return .red
        }
    }

    // MARK: - Typewriter

    private func startTyping(_ fullText: String) {
        typingTask?.cancel()
        displayedText = ""
        isTyping = true
        typingTask = Task {
            for char in fullText {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 35_000_000)
                if Task.isCancelled { break }
                displayedText.append(char)
            }
            isTyping = false
        }
    }

    private func skipTyping() {
        typingTask?.cancel()
        displayedText = dialogueViewModel.currentLine.text
        isTyping = false
    }

    private func handleDialogueTap() {
        if isTyping {
            skipTyping()
        } else if dialogueViewModel.isLastLine {
            withAnimation { dialogueDone = true }
        } else {
            dialogueViewModel.advance()
        }
    }

    // MARK: - Outcome Screen

    private func outcomeScreen(title: String, subtitle: String, won: Bool) -> some View {
        VStack(spacing: 24) {
            Text(won ? "" : "").font(.system(size: 80))
            Text(title).font(.custom("Cute-Dino", size: 36)).fontWeight(.bold)
            Text(subtitle)
                .font(.custom("Cute-Dino", size: 20))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: {
                financeViewModel.reset()
                financeViewModel.shouldResetToHome = true
            }) {
                Text("Play Again")
                    .font(.custom("Cute-Dino", size: 22))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Rectangle().fill(Color.accentColor))
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private func formatted(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack { FinanceView(stage: 0) }
        .environment(FinanceViewModel())
}

// MARK: - Eclair Reflection Sheet

struct EclairReflectionSheet: View {
    let isReflecting: Bool
    let reflectionText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Eclair's Take")
                    .font(.custom("Cute-Dino", size: 30))
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            if isReflecting {
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Hmm, let me think... ")
                        .font(.custom("Cute-Dino", size: 22))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reflectionText.isEmpty {
                Text("Tap \"Ask Eclair\" to get Eclair's thoughts on your moves this week!")
                    .font(.custom("Cute-Dino", size: 20))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                ScrollView {
                    Text(reflectionText)
                        .font(.custom("Cute-Dino", size: 24))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 54/255, green: 54/255, blue: 54/255).opacity(0.08))
                        )
                }
            }

            Spacer()
        }
        .padding(28)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Scroll helpers

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollIndicatorView: View {
    let contentHeight: CGFloat
    let scrollOffset: CGFloat
    let availableHeight: CGFloat

    private var thumbHeight: CGFloat {
        guard contentHeight > availableHeight else { return availableHeight }
        return max(30, availableHeight * availableHeight / contentHeight)
    }

    private var thumbOffset: CGFloat {
        guard contentHeight > availableHeight else { return 0 }
        let maxOffset = availableHeight - thumbHeight
        let maxScroll = contentHeight - availableHeight
        return min(maxOffset, max(0, scrollOffset / maxScroll * maxOffset))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color(red: 101/255, green: 67/255, blue: 33/255).opacity(0.25))
            Capsule()
                .fill(Color(red: 101/255, green: 67/255, blue: 33/255))
                .frame(height: thumbHeight)
                .offset(y: thumbOffset)
        }
        .frame(width: 6)
    }
}
