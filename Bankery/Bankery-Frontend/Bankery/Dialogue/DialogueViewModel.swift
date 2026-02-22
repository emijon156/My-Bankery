//
//  DialogueViewModel.swift
//  Bankery
//

import Foundation
import Observation

@Observable
class DialogueViewModel {

    // MARK: - Intro dialogue lines (before FinanceView)
    private let allLines: [DialogueLine] = [

        // Stage 0 – intro
        DialogueLine(speaker: "Eclair", text: "Welcome! I'm Eclair, owner of Bankery.",                         poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(speaker: "Eclair", text: "Things haven't been going so well lately…",                      poseImageName: "stand_speak",         stage: 0),
        DialogueLine(speaker: "Eclair", text: "Our checking account is running low, and we still have loans.",   poseImageName: "stand_worried",        stage: 0),
        DialogueLine(speaker: "Eclair", text: "I need someone smart to help manage our finances.",               poseImageName: "stand_speak",         stage: 0),
        DialogueLine(speaker: "Eclair", text: "Think you're up for it? Let's get started!",                      poseImageName: "stand_speak_armsout", stage: 0),

        // Stage 1 – after day 1
        DialogueLine(speaker: "Eclair", text: "Nice work! We made it through the first day.",                    poseImageName: "stand_speak_armsout", stage: 1),
        DialogueLine(speaker: "Eclair", text: "Keep an eye on the loan — those interest payments add up!",       poseImageName: "stand_worried",        stage: 1),

        // Stage 2 – after day 2
        DialogueLine(speaker: "Eclair", text: "We're making progress. Stay focused!",                            poseImageName: "stand_speak",         stage: 2),
        DialogueLine(speaker: "Eclair", text: "If we keep this up, we'll pay off the loan in no time.",          poseImageName: "stand_speak_armsout", stage: 2),
    ]

    // MARK: - Finance screen dialogue lines (shown inside FinanceView per stage)
    private let allFinanceLines: [DialogueLine] = [

        // Stage 0 – first time seeing the finance screen
        DialogueLine(speaker: "Eclair", text: "Welcome to the balance sheet! This is how we track the bakery's finances.",                     poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(speaker: "Eclair", text: "On the left you'll see Assets — everything the bakery owns or has money in.",                    poseImageName: "stand_speak",         stage: 0),
        DialogueLine(speaker: "Eclair", text: "Checking is our everyday cash account. We pay bills and buy supplies from here.",                poseImageName: "stand_speak",         stage: 0),
        DialogueLine(speaker: "Eclair", text: "Savings holds money we've set aside. It earns a little interest over time — nice!",              poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(speaker: "Eclair", text: "Investment is money we've put into growing the business — think new equipment funds.",           poseImageName: "stand_speak",         stage: 0),
        DialogueLine(speaker: "Eclair", text: "Inventory is the value of all the pastries and ingredients we have on hand.",                    poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(speaker: "Eclair", text: "Equipment is the worth of our ovens, mixers, and tools. They lose value slowly over time.",      poseImageName: "stand_worried",        stage: 0),
        DialogueLine(speaker: "Eclair", text: "On the right are Liabilities — money we owe to others.",                                        poseImageName: "stand_speak",         stage: 0),
        DialogueLine(speaker: "Eclair", text: "The Loan is what we borrowed to open the bakery. Our goal is to get it to zero!",               poseImageName: "stand_worried",        stage: 0),
        DialogueLine(speaker: "Eclair", text: "Accounts Payable is what we owe suppliers for ingredients we already used.",                    poseImageName: "stand_worried",        stage: 0),
        DialogueLine(speaker: "Eclair", text: "Net Worth = Total Assets minus Total Liabilities. Keep it positive and growing!",                poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(speaker: "Eclair", text: "Got it? Great! Tap Next Week to see what happens after our first week of business!",             poseImageName: "stand_speak_armsout", stage: 0),

        // Stage 1 – after week 1
        DialogueLine(speaker: "Eclair", text: "See how the numbers shifted? Revenue came in and we paid some bills.",                          poseImageName: "stand_speak",         stage: 1),
        DialogueLine(speaker: "Eclair", text: "Accounts Payable went up — we ordered more flour and butter for next week.",                    poseImageName: "stand_worried",        stage: 1),
        DialogueLine(speaker: "Eclair", text: "If Checking ever hits zero it's game over, so always keep some cash there!",                    poseImageName: "stand_worried",        stage: 1),
        DialogueLine(speaker: "Eclair", text: "Ready for another week? Tap Next Week!",                                                        poseImageName: "stand_speak_armsout", stage: 1),

        // Stage 2 – after week 2
        DialogueLine(speaker: "Eclair", text: "Great job so far! The loan balance is slowly shrinking.",                                        poseImageName: "stand_speak_armsout", stage: 2),
        DialogueLine(speaker: "Eclair", text: "Keep Savings healthy — it's our safety net if Checking ever dips.",                             poseImageName: "stand_speak",         stage: 2),
        DialogueLine(speaker: "Eclair", text: "Inventory is down — we sold a lot of pastries this week. Profitable!",                          poseImageName: "stand_speak_armsout", stage: 2),
        DialogueLine(speaker: "Eclair", text: "Every week we pay down the loan a little more. We're getting there!",                           poseImageName: "stand_speak_armsout", stage: 2),
    ]

    // MARK: - Current stage lines
    private(set) var lines: [DialogueLine] = []
    private(set) var currentIndex: Int = 0
    private(set) var currentStage: Int = 0

    init() {
        loadStage(0)
    }

    // MARK: - Public API

    var currentLine: DialogueLine { lines[currentIndex] }
    var isLastLine: Bool          { currentIndex >= lines.count - 1 }
    var progress: Double          { Double(currentIndex + 1) / Double(lines.count) }

    func advance() {
        guard !isLastLine else { return }
        currentIndex += 1
    }

    /// Load intro-scene lines for the given stage.
    func loadStage(_ stage: Int) {
        let filtered = allLines.filter { $0.stage == stage }
        lines        = filtered.isEmpty ? allLines.filter { $0.stage == 0 } : filtered
        currentIndex = 0
        currentStage = stage
    }

    /// Load finance-screen lines for the given stage.
    func loadFinanceStage(_ stage: Int) {
        let filtered = allFinanceLines.filter { $0.stage == stage }
        lines        = filtered.isEmpty ? allFinanceLines.filter { $0.stage == 0 } : filtered
        currentIndex = 0
        currentStage = stage
    }

    func reset() {
        loadStage(0)
    }
}
