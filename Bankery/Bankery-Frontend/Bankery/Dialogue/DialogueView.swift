//
//  DialogueView.swift
//  Bankery
//

import SwiftUI

struct DialogueView: View {
    let stage: Int

    @State private var viewModel = DialogueViewModel()
    @State private var goToFinance = false
    @Namespace private var zoomNamespace


    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil

    init(stage: Int = 0) {
        self.stage = stage
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: - Scene Layers
                Image("Wall_background")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                Image("background_walldecor")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                Image(viewModel.currentLine.poseImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 1220)
                    .position(x: 800, y: 450)

                Image("foreground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // MARK: - Dialogue Panel (bottom 1/4)
                VStack {
                    Spacer()

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 54/255, green: 54/255, blue: 54/255))
                            .ignoresSafeArea(edges: .bottom)

                        HStack(alignment: .top, spacing: 16) {
                            

                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.currentLine.speaker)
                                    .font(.custom("Cute-Dino", size: 42))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Text(displayedText)
                                    .font(.custom("Cute-Dino", size: 30))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity,
                                           minHeight: textHeight(for: viewModel.currentLine.text),
                                           alignment: .topLeading)
                            }
                            .padding(.top, 30)
                        }
                        .padding(.horizontal, 30)
                    }
                    .frame(height: geo.size.height * 0.25)
                    .padding(.horizontal, 120)
                    .padding(.bottom, 26)

                }
                .ignoresSafeArea(edges: .bottom)

                // Progress dots + tap hint
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 7) {
                            ForEach(0..<viewModel.lines.count, id: \.self) { index in
                                Circle()
                                    .fill(index == viewModel.currentIndex
                                          ? Color.white
                                          : Color.white.opacity(0.4))
                                    .frame(width: 6, height: 6)
                                    .animation(.easeInOut, value: viewModel.currentIndex)
                            }
                        }
                        .padding(.leading, 24)

                        Spacer()

                        Text(isTyping ? "Tap to skip..." : "Tap to continue →")
                            .font(.custom("Cute-Dino", size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.trailing, 24)
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 120)
                }
                
                .ignoresSafeArea(edges: .bottom)
            }
            
            //.ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { handleTap() }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $goToFinance) {
                if #available(iOS 18, *) {
                    FinanceView(stage: stage)
                        .navigationTransition(.zoom(sourceID: "start", in: zoomNamespace))
                } else {
                    FinanceView(stage: stage)
                }
            }
            .onAppear {
                viewModel.loadStage(stage)
                startTyping(viewModel.currentLine.text)
            }
            .onChange(of: viewModel.currentIndex) { _, _ in
                startTyping(viewModel.currentLine.text)
            }
        }
        .ignoresSafeArea()
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
        displayedText = viewModel.currentLine.text
        isTyping = false
    }

    private func handleTap() {
        if isTyping {
            skipTyping()
        } else if viewModel.isLastLine {
            goToFinance = true
        } else {
            viewModel.advance()
        }
    }

    private func textHeight(for text: String) -> CGFloat {
        let lines = max(1, text.count / 40 + 1)
        return CGFloat(lines) * 22
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        DialogueView(stage: 0)
    }
    .environment(FinanceViewModel())
}
