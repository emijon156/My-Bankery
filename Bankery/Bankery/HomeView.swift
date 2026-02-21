//
//  HomeView.swift
//  Bankery
//
//  Created by Emily Jon on 2/21/26.
//

import SwiftUI

struct HomeView: View {
    @State private var goToScene1 = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                Button(action: {
                    goToScene1 = true
                }) {
                    Text("Start")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 220)
                        .background(Rectangle().fill(Color.accentColor))
                        .shadow(radius: 10)
                }
            }
            .navigationDestination(isPresented: $goToScene1) {
                Scene1View()
            }
        }
    }
}

#Preview {
    HomeView()
}
