//
//  DialogueLine.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import Foundation

// MARK: - Choice Option
struct DialogueChoice: Identifiable {
    let id = UUID()
    let label: String        // short button label shown to the player
    let response: String     // Eclair's follow-up text after the player picks this option
    let eventKey: String     // backend event key: "oven_repair" | "windfall" | "permit_fine" | ""
    let choiceIndex: Int     // 0 = first option, 1 = second option
}

// MARK: - Dialogue Line
struct DialogueLine: Identifiable {
    let id = UUID()
    let speaker: String
    let text: String
    let poseImageName: String
    let stage: Int          // 0 = Scene 1 intro, 1 = Issue 1, 2 = Issue 2, …
    let choices: [DialogueChoice]?  // nil → normal tap-to-continue; non-nil → show buttons

    init(
        speaker: String,
        text: String,
        poseImageName: String,
        stage: Int,
        choices: [DialogueChoice]? = nil
    ) {
        self.speaker = speaker
        self.text = text
        self.poseImageName = poseImageName
        self.stage = stage
        self.choices = choices
    }
}
