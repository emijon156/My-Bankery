//
//  InvestmentView.swift
//  Bankery
//

import SwiftUI

struct InvestmentView: View {
    @Environment(FinanceViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("Computer_overlay")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {


                        HStack {
                            Button { dismiss() } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.custom("Cute-Dino", size: 18))
                                .foregroundColor(.primary)
                            }
                            Spacer()
                            Text("Investments")
                                .font(.custom("Cute-Dino", size: 28))
                                .foregroundColor(.primary)
                            Spacer()
                            // Mirror of back button for centering
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .opacity(0)
                        }


                        HStack(spacing: 12) {
                            Image("stand_speak_armsout")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                            Text("These are real-time prices from the market! Investing means your money works while you bake. ")
                                .font(.custom("Cute-Dino", size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)

                        if vm.investmentsLoading {
                            ProgressView("Loading market data…")
                                .font(.custom("Cute-Dino", size: 16))
                                .padding(.top, 40)
                        } else if let err = vm.investmentsError {
                            VStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Couldn't load market data")
                                    .font(.custom("Cute-Dino", size: 20))
                                Text(err)
                                    .font(.custom("Cute-Dino", size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    Task { await vm.fetchTopInvestments() }
                                }
                                .font(.custom("Cute-Dino", size: 16))
                                .padding(.top, 4)
                            }
                            .padding(.top, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(vm.topTickers) { ticker in
                                    tickerCard(ticker)
                                }
                            }
                        }

                        VStack(spacing: 8) {
                            Text("Ready to invest for real?")
                                .font(.custom("Cute-Dino", size: 18))
                                .foregroundColor(.secondary)

                            Button(action: openFidelity) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .font(.title2)
                                    Text("Open Fidelity")
                                        .font(.custom("Cute-Dino", size: 24))
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.13, green: 0.28, blue: 0.60),
                                                 Color(red: 0.20, green: 0.43, blue: 0.82)],
                                        startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(red: 0.13, green: 0.28, blue: 0.60).opacity(0.4),
                                        radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, geo.size.height * 0.28)
                    }
                    .padding(.horizontal, 142)
                    .padding(.top, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .task { await vm.fetchTopInvestments() }
    }

    // MARK: - Ticker Card

    private func tickerCard(_ ticker: TopTicker) -> some View {
        let isPositive = ticker.dailyChangePct >= 0
        return HStack(spacing: 0) {
            // Symbol badge
            Text(ticker.symbol)
                .font(.custom("Cute-Dino", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 90)
                .padding(.vertical, 18)
                .background(Color(red: 54/255, green: 54/255, blue: 54/255))

            // Price
            VStack(alignment: .leading, spacing: 2) {
                Text(formatted(ticker.price))
                    .font(.custom("Cute-Dino", size: 22))
                    .foregroundColor(.primary)
                Text("per share")
                    .font(.custom("Cute-Dino", size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            Spacer()

            // Daily change badge
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.footnote)
                Text(String(format: "%+.2f%%", ticker.dailyChangePct))
                    .font(.custom("Cute-Dino", size: 18))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isPositive ? Color.green : Color.red)
            .cornerRadius(10)
            .padding(.trailing, 16)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Fidelity deeplink

    private func openFidelity() {
        let appScheme = URL(string: "fidelityinvestments://")!
        let web       = URL(string: "https://www.fidelity.com")!
        openURL(appScheme) { accepted in
            if !accepted { openURL(web) }
        }
    }

    // MARK: - Helpers

    private func formatted(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle    = .currency
        f.currencyCode   = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack { InvestmentView() }
        .environment(FinanceViewModel())
}
