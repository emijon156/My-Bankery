//
//  DialogueView.swift
//  Bankery
//

import SwiftUI
import AVFoundation

struct DialogueView: View {
    let stage: Int

    @State private var viewModel = DialogueViewModel()
    @State private var goToFinance = false
    @State private var showEndOverlay = false
    @Namespace private var zoomNamespace
    @Environment(FinanceViewModel.self) private var financeViewModel
    @Environment(\.dismiss) private var dismiss

    // Typewriter
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil

    // Audio
    @State private var audio = AudioPlayerManager()

    // Choice state
    @State private var pendingChoiceResponse: String? = nil

    private var showChoiceButtons: Bool {
        guard let choices = viewModel.currentLine.choices else { return false }
        return !choices.isEmpty && !isTyping && pendingChoiceResponse == nil
    }

    init(stage: Int = 0) {
        self.stage = stage
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
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
                                    .font(.custom("Cute-Dino", size: 35))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Text(displayedText)
                                    .font(.custom("Cute-Dino", size: 25))
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
                    .padding(.bottom, showChoiceButtons ? 26 : 26)
                }
                .ignoresSafeArea(edges: .bottom)

                // MARK: - Choice Buttons (shown over dialogue panel)
                if showChoiceButtons, let choices = viewModel.currentLine.choices {
                    VStack {
                        Spacer()
                        HStack(spacing: 16) {
                            ForEach(choices) { choice in
                                Button(action: { selectChoice(choice) }) {
                                    Text(choice.label)
                                        .font(.custom("Cute-Dino", size: 22))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(choiceColor(index: choice.choiceIndex))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 140)
                        .padding(.bottom, geo.size.height * 0.25 + 36)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.25), value: showChoiceButtons)
                }

                // MARK: - Progress dots + tap hint
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

                        if !showChoiceButtons {
                            Text(isTyping ? "Tap to skip..." : "Tap to continue →")
                                .font(.custom("Cute-Dino", size: 16))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.trailing, 24)
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 120)
                }
                .ignoresSafeArea(edges: .bottom)

                // MARK: - End Overlay (stage 5 terminal)
                if showEndOverlay {
                    endOverlay
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: showEndOverlay)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { handleTap() }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $goToFinance) {
                    FinanceView(stage: stage)
                
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

    // MARK: - End Overlay

    private var endOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 28) {
                Text("What a journey!")
                    .font(.custom("Cute-Dino", size: 42))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("You helped Eclair master the Bankery's finances.\nThanks for playing!")
                    .font(.custom("Cute-Dino", size: 26))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                Button(action: {
                    financeViewModel.reset()
                    financeViewModel.shouldResetToHome = true
                }) {
                    Text("Play Again")
                        .font(.custom("Cute-Dino", size: 28))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 64)
                        .background(Rectangle().fill(Color(red: 54/255, green: 54/255, blue: 54/255)))
                        .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Choice Selection

    private func selectChoice(_ choice: DialogueChoice) {
        pendingChoiceResponse = choice.response
        startTyping(choice.response)
        // Fire backend event (non-blocking)
        if !choice.eventKey.isEmpty {
            Task {
                await financeViewModel.applyEvent(key: choice.eventKey, choice: choice.choiceIndex)
            }
        }
    }

    private func choiceColor(index: Int) -> Color {
        index == 0
            ? Color(red: 0.18, green: 0.55, blue: 0.34)   // green-ish for option A
            : Color(red: 0.70, green: 0.35, blue: 0.10)   // amber-ish for option B
    }

    // MARK: - Typewriter

    private func startTyping(_ fullText: String) {
        typingTask?.cancel()
        displayedText = ""
        isTyping = true
        audio.play()
        typingTask = Task {
            for char in fullText {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 35_000_000)
                if Task.isCancelled { break }
                displayedText.append(char)
            }
            audio.stop()
            isTyping = false
        }
    }

    private func skipTyping() {
        typingTask?.cancel()
        audio.stop()
        displayedText = pendingChoiceResponse ?? viewModel.currentLine.text
        isTyping = false
    }

    private func handleTap() {
        guard !showChoiceButtons else { return }   // ignore taps while choice buttons are visible

        if isTyping {
            skipTyping()
        } else if pendingChoiceResponse != nil {
            // Response has been read; advance past the choice line
            pendingChoiceResponse = nil
            if viewModel.isLastLine {
                triggerEndOrFinance()
            } else {
                viewModel.advance()
            }
        } else if viewModel.isLastLine {
            triggerEndOrFinance()
        } else {
            viewModel.advance()
        }
    }

    private func triggerEndOrFinance() {
        if stage == 5 {
            withAnimation { showEndOverlay = true }
        } else {
            goToFinance = true
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

