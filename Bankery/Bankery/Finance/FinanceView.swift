//
//  FinanceView.swift
//  Bankery
//

import SwiftUI

struct FinanceView: View {
    let stage: Int
    @State private var financeViewModel  = FinanceViewModel()
    @State private var dialogueViewModel = DialogueViewModel()
    @State private var goToNextDialogue  = false

    // Typewriter
    @State private var displayedText: String = ""
    @State private var isTyping: Bool  = false
    @State private var typingTask: Task<Void, Never>? = nil
    @State private var dialogueDone: Bool = false

    init(stage: Int = 0) { self.stage = stage }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("Computer_overlay")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                if financeViewModel.outcome == .lost {
                    outcomeScreen(title: "Game Over 💸",
                                  subtitle: "Your checking account ran out of money.", won: false)
                } else if financeViewModel.outcome == .won {
                    outcomeScreen(title: "You Won! 🎉",
                                  subtitle: "You paid off the loan. Bankery is saved!", won: true)
                } else {
                    // ── Main content ──
                    ScrollView {
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

                            // Next Week button — unlocked after all dialogue
                            if dialogueDone {
                                Button(action: {
                                    Task {
                                        await financeViewModel.nextMonth()
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
                        .padding(.top, 80)
                        .padding(.bottom, geo.size.height * 0.28)
                        .animation(.easeInOut, value: dialogueDone)
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
                                        .font(.custom("Cute-Dino", size: 22))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentColor)

                                    Text(displayedText)
                                        .font(.custom("Cute-Dino", size: 20))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                                .padding(.top, 16)

                                Spacer()
                            }
                            .padding(.horizontal, 20)

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
                        .contentShape(Rectangle())
                        .onTapGesture { handleDialogueTap() }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToNextDialogue) {
            DialogueView(stage: stage + 1)
        }
        .onAppear {
            dialogueViewModel.loadFinanceStage(stage)
            startTyping(dialogueViewModel.currentLine.text)
        }
        .onChange(of: dialogueViewModel.currentIndex) { _, _ in
            startTyping(dialogueViewModel.currentLine.text)
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
            Text(won ? "🎉" : "💸").font(.system(size: 80))
            Text(title).font(.custom("Cute-Dino", size: 36)).fontWeight(.bold)
            Text(subtitle)
                .font(.custom("Cute-Dino", size: 20))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: { financeViewModel.reset() }) {
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
}
