//
//  HomeView.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(FinanceViewModel.self) private var financeViewModel
    @State private var goToDialogue = false
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Image("Bankery_front")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Button(action: {
                    Task {
                        await financeViewModel.initGame()
                        goToDialogue = true
                    }
                }) {
                    Group {
                        if financeViewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Start")
                                .font(.custom("Cute-Dino", size: 42))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 340, height: 80)
                    .background(Rectangle().fill(Color(red: 54/255, green: 54/255, blue: 54/255)))
                    .shadow(radius: 10)
                }
                .disabled(financeViewModel.isLoading)
                .padding(.bottom, 75)
            }
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToDialogue) {
                DialogueView()
                    .navigationTransition(.zoom(sourceID: "start", in: zoomNamespace))
            }
            .matchedTransitionSource(id: "start", in: zoomNamespace)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView()
        .environment(FinanceViewModel())
}
