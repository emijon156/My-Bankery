//
//  BankeryApp.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import SwiftUI

@main
struct BankeryApp: App {
    @State private var financeViewModel = FinanceViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(financeViewModel)
        }
    }
}
