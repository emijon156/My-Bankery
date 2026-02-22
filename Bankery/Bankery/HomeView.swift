//
//  HomeView.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import SwiftUI

struct HomeView: View {
    @State private var goToDialogue = false
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                Button(action: {
                    goToDialogue = true
                }) {
                    Text("Start")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 80)
                        .background(Rectangle().fill(Color.accentColor))
                        .shadow(radius: 10)
                }
                .padding(.bottom, 300)
            }
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
}
