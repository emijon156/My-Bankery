//
//  DialogueViewModel.swift
//  Bankery
//

import Foundation
import Observation

// MARK: - Narrative Stage Constants
// Stage 0: Scene 1 – intro (DialogueView)  → FinanceView stage 0 (balance sheet tutorial)
// Stage 1: Issue 1 – Oven (DialogueView)   → FinanceView stage 1
// Stage 2: Issue 2 – Viral (DialogueView)  → FinanceView stage 2
// Stage 3: Issue 3 – Inspector (DialogueView) → FinanceView stage 3
// Stage 4: Scene 2 – Investing (DialogueView) → FinanceView stage 4
// Stage 5: End Scene (DialogueView, terminal – no FinanceView)

@Observable
class DialogueViewModel {

    // MARK: - Intro / inter-scene dialogue (shown in DialogueView)
    private let allLines: [DialogueLine] = [

        // ── Stage 0 · SCENE 1: Outside the Bankery ──────────────────────────
        DialogueLine(
            speaker: "Eclair",
            text: "Oh! Hi there! You must be the Financial Assistant I hired! Welcome to the Bankery! I'm Eclair.",
            poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "I'm great at making the 'dough,' but I'm... well, a little bit lost when it comes to managing it.",
            poseImageName: "stand_speak", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Every time I see a spreadsheet, my brain feels like over-proofed bread!",
            poseImageName: "stand_worried", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "I need your savvy eyes to help me make the big calls so we can keep this shop afloat.",
            poseImageName: "stand_speak", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Ready to help a panda out?",
            poseImageName: "stand_speak_armsout", stage: 0),

        // ── Stage 1 · ISSUE 1: Oven breaks down ($1,500) ────────────────────
        DialogueLine(
            speaker: "Eclair",
            text: "Eek! My oven let out a tiny 'poof' and now it's taking a nap. I'm in a real sticky situation — and not the good, glaze-covered kind of sticky. What should I do?!",
            poseImageName: "oven", stage: 1),
        DialogueLine(
            speaker: "Eclair",
            text: "The repair shop says it'll cost $1,500 to fix. We could put it on credit now, or tough it out with the remaining ovens...",
            poseImageName: "oven",
            stage: 1,
            choices: [
                DialogueChoice(
                    label: "Pay $1,500 on Credit",
                    response: "Ooh, a magic plastic card! So we get a shiny fixed oven right now and I can keep making my signature 'Bamboo-zled' brownies? That sounds like a piece of cake! ... Wait... the bank says if I don't pay them back fast, the $1,500 turns into $1,600... then $1,700? It's like a sourdough starter that grows into a debt monster if I'm not careful!",
                    eventKey: "oven_repair",
                    choiceIndex: 0),
                DialogueChoice(
                    label: "Bear with the other ovens",
                    response: "You're right, let's keep the credit card in the cookie jar for now. I'll just have to shuffle my trays between the two tiny ovens left — it'll be like a game of musical chairs... but with hot muffins! Oof, my paws are getting a workout! The line is getting a bit long out there because I can only bake six cookies at a time. I hope the customers don't get 'hangry' while they wait...",
                    eventKey: "oven_repair",
                    choiceIndex: 1),
            ]),

        // ── Stage 2 · ISSUE 2: We Go VIRAL ──────────────────────────────────
        DialogueLine(
            speaker: "Eclair",
            text: "Oh my bamboo! Did you see?! That video of me accidentally sneezing powdered sugar on a croissant got a million views! Everyone wants to come to the Bankery now.",
            poseImageName: "stand_speak_armsout", stage: 2),
        DialogueLine(
            speaker: "Eclair",
            text: "We have so much extra 'dough' from the rush... what do we do with it?!",
            poseImageName: "stand_speak_armsout",
            stage: 2,
            choices: [
                DialogueChoice(
                    label: "Put it in the HYSA",
                    response: "Wait, so the bank pays us just to keep the money there? It's like a snack that grows more snacks while you sleep!",
                    eventKey: "windfall",
                    choiceIndex: 0),
                DialogueChoice(
                    label: "Buy the rose-gold whisk",
                    response: "We're superstars now! I saw this whisk online that's made of solid rose gold. It doesn't actually bake faster, but think of how cute it'll look in our next video!",
                    eventKey: "windfall",
                    choiceIndex: 1),
            ]),

        // ── Stage 3 · ISSUE 3: Health Inspector ─────────────────────────────
        DialogueLine(
            speaker: "Eclair",
            text: "Oh, bamboo-zlesticks! I thought that permit was a coaster for my tea! $200? That's a lot of cupcakes... What do we do, Assistant?",
            poseImageName: "stand_worried",
            stage: 3,
            choices: [
                DialogueChoice(
                    label: "Pay the $200 fine",
                    response: "You're right. It's better to just take the hit and keep the ovens humming. It hurts my tummy to see that much money go away for a piece of paper, but at least we can keep the doors open and keep our customers happy.",
                    eventKey: "permit_fine",
                    choiceIndex: 0),
                DialogueChoice(
                    label: "Appeal the fine",
                    response: "Appeal it? Yeah! Maybe I can convince the council that 'Cute Pandas' should be exempt from paperwork! But... wait... if we appeal, we have to lock the doors until the hearing? That's two whole weeks of no baking! I hope the money we save on the fine is worth the money we lose from having no customers...",
                    eventKey: "permit_fine",
                    choiceIndex: 1),
            ]),

        // ── Stage 4 · SCENE 2: After some time — Investing ──────────────────
        DialogueLine(
            speaker: "Eclair",
            text: "Phew! Look at our jars, Assistant! After all that hard work, we actually have a little 'mountain' of extra profit sitting here. It's making me feel like a very fancy business-panda!",
            poseImageName: "stand_speak_armsout", stage: 4),
        DialogueLine(
            speaker: "Eclair",
            text: "But I was reading this leaf-let... it says that if we just let our money sit in this jar, it doesn't grow. It just... sits. I want our money to be like my bread — I want it to rise!",
            poseImageName: "stand_speak", stage: 4),
        DialogueLine(
            speaker: "Eclair",
            text: "I heard that if we 'invest' it, our money goes out into the world and brings back friends! But there are so many choices... it's a bit over-beaver-whelming. What's our move?",
            poseImageName: "stand_speak", stage: 4),

        // ── Stage 5 · END SCENE ──────────────────────────────────────────────
        DialogueLine(
            speaker: "Eclair",
            text: "What a month! You really saved my fur.",
            poseImageName: "stand_speak_armsout", stage: 5),
        DialogueLine(
            speaker: "Eclair",
            text: "I used to think 'finances' were just scary numbers that lived in a basement, but you showed me they're just another kind of recipe.",
            poseImageName: "stand_speak", stage: 5),
        DialogueLine(
            speaker: "Eclair",
            text: "Whether it's choosing between credit and cash, or letting our 'honey-money' grow in a safe spot, I feel way more confident now!",
            poseImageName: "stand_speak_armsout", stage: 5),
    ]

    // MARK: - Finance-screen dialogue (shown inside FinanceView per stage)
    private let allFinanceLines: [DialogueLine] = [

        // Stage 0 – balance sheet tutorial
        DialogueLine(
            speaker: "Eclair",
            text: "Welcome to the balance sheet! Think of it as the Bankery's recipe card for money.",
            poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "On the left are Assets — everything we own. Checking is our everyday cash drawer; we pay bills and buy supplies from here.",
            poseImageName: "stand_speak", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Savings is money tucked away for later. It earns a little interest — like bread that rises overnight!",
            poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Investment is money working hard in the background to grow over time — roughly 7% a year!",
            poseImageName: "stand_speak", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Inventory is our pastries and ingredients on hand. Equipment covers our ovens and mixers — they lose a tiny bit of value each week.",
            poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "On the right are Liabilities — money we still owe. The Loan is what we borrowed to open the Bankery. Our goal: get it to zero!",
            poseImageName: "stand_worried", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Net Worth = Total Assets minus Total Liabilities. Keep it positive and growing!",
            poseImageName: "stand_speak_armsout", stage: 0),
        DialogueLine(
            speaker: "Eclair",
            text: "Got it? Wonderful! Tap 'Next Week' and let's start our first week of business! Want me to look over your decisions? Just ask!",
            poseImageName: "stand_speak_armsout", stage: 0),

        // Stage 1 – after oven issue
        DialogueLine(
            speaker: "Eclair",
            text: "See how the numbers shifted after our oven situation? Every decision leaves a mark on the balance sheet!",
            poseImageName: "stand_speak", stage: 1),
        DialogueLine(
            speaker: "Eclair",
            text: "If we used credit, notice the Loan went up — interest will quietly grow on that extra debt each week.",
            poseImageName: "stand_worried", stage: 1),
        DialogueLine(
            speaker: "Eclair",
            text: "Ready to keep baking? Tap 'Next Week'!",
            poseImageName: "stand_speak_armsout", stage: 1),

        // Stage 2 – after viral video
        DialogueLine(
            speaker: "Eclair",
            text: "Look at those numbers glow! Going viral gave our Checking account a real boost.",
            poseImageName: "stand_speak_armsout", stage: 2),
        DialogueLine(
            speaker: "Eclair",
            text: "Moving money to Savings earns interest over time. Spending it is fun, but watch that Loan balance!",
            poseImageName: "stand_speak", stage: 2),
        DialogueLine(
            speaker: "Eclair",
            text: "Tap 'Next Week' and let's ride this wave! Want me to look over your decisions? Just ask!",
            poseImageName: "stand_speak_armsout", stage: 2),

        // Stage 3 – after health inspector
        DialogueLine(
            speaker: "Eclair",
            text: "The permit situation is handled. Every choice has a financial consequence — you're learning how to read the recipe!",
            poseImageName: "stand_speak", stage: 3),
        DialogueLine(
            speaker: "Eclair",
            text: "Paying a fine hurts a little now but keeps revenue flowing. Appealing saves the fine but loses income for weeks — always weigh the tradeoff!",
            poseImageName: "stand_worried", stage: 3),
        DialogueLine(
            speaker: "Eclair",
            text: "Tap 'Next Week' and let's keep the ovens humming! Want me to look over your decisions? Just ask!",
            poseImageName: "stand_speak_armsout", stage: 3),

        // Stage 4 – investing
        DialogueLine(
            speaker: "Eclair",
            text: "This is our Investment account — money we've put to work, growing at roughly 7% a year.",
            poseImageName: "stand_speak_armsout", stage: 4),
        DialogueLine(
            speaker: "Eclair",
            text: "Each week it earns a return automatically. That's compound growth — your money makes more money while you sleep!",
            poseImageName: "stand_speak", stage: 4),
        DialogueLine(
            speaker: "Eclair",
            text: "The bigger the Investment balance, the faster it grows. Consider transferring some Savings there to put it to work.",
            poseImageName: "stand_speak_armsout", stage: 4),
        DialogueLine(
            speaker: "Eclair",
            text: "Amazing work this month! Tap 'Next Week' to see your final results.",
            poseImageName: "stand_speak_armsout", stage: 4),
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

    func loadStage(_ stage: Int) {
        let filtered = allLines.filter { $0.stage == stage }
        lines        = filtered.isEmpty ? allLines.filter { $0.stage == 0 } : filtered
        currentIndex = 0
        currentStage = stage
    }

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
