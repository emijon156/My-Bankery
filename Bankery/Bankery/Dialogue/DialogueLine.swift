//
//  DialogueLine.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import Foundation

struct DialogueLine: Identifiable {
    let id = UUID()
    let speaker: String
    let text: String
    let poseImageName: String
    let stage: Int          // 0 = intro, 1 = after month 1, 2 = after month 2, …
}
