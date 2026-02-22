# Bankery 

**Bankery** is financial literacy game that teaches real personal finance concepts through immersive narrative gameplay. Players step into the role of a financial advisor for Eclair, an adorably overwhelmed panda bakery owner, and manage her actual bank accounts in real-time.

Instead of simulating money with fake numbers, Bankery is backed by the Capital One Nessie API. Every deposit, loan repayment, fund transfer, and purchase is a live banking transaction hitting real account infrastructure.

## Features

* **Real Banking Infrastructure:** Powered by the Capital One Nessie API, players create a live customer profile with Checking, Savings, and Investment accounts. The full transaction ledger is queryable at any point.
* **AI Financial Advisor:** Eclair's inner voice is powered by Google Gemini 2.5 Flash. At the end of each week, the AI analyzes the player's live balance sheet and action log to deliver brutally honest, in-character feedback using baking metaphors.
* **Live Market Data:** The investments screen displays real-time stock prices and daily percent changes for major tickers (SPY, AAPL, MSFT, NVDA, AMZN) via `yfinance`, giving players exposure to actual market conditions.
* **Narrative Crises:** Players must navigate recurring expenses (rent, wages, utilities) and sudden narrative events—like an unexpected repair bill, a sudden windfall, or a regulatory fine—mapped to real concepts like credit risk and opportunity cost.

## Technology Stack

**Frontend (iOS)**

* **Language/Framework:** Swift, SwiftUI
* **Architecture:** Clean MVVM
* **Features:** `@Observable` and `@Environment` for reactive state sharing, custom typewriter dialogue engine, animated scroll indicators, and hand-drawn UI assets.

**Backend**

* **Language/Framework:** Python, FastAPI
* **Data Layer:** Capital One Nessie API
* **Market Data:** `yfinance` (`fast_info`)
* **AI Integration:** Google Gemini API (2.5 Flash, thinking disabled for ultra-low latency)
* **Deployment:** Cloudflare Tunnels (generating a public HTTPS endpoint to bypass local hackathon network restrictions)

## Technical Challenges Overcome

* **API Staleness:** Real banking APIs have latency between writing a transaction and reading the updated ledger. We engineered an in-memory balance cache layer in our Python backend to solve Nessie's transaction staleness, ensuring UI balance reads are instantly authoritative after every write.
* **LLM Latency:** To keep the game loop immersive and snappy, we explicitly disabled the "thinking" phase in Gemini 2.5 Flash. This provided the low latency needed for a game UI while still maintaining Eclair's strict persona and context-aware prompt engineering.

## Getting Started

### Prerequisites

* Xcode 15+ (for iOS Frontend)
* Python 3.9+
* Capital One Nessie API Key
* Google Gemini API Key

### Backend Setup

1. Clone the repository and navigate to the backend directory:
```bash
cd bankery/backend

```


2. Install the required Python dependencies:
```bash
pip install -r requirements.txt

```


3. Create a `.env` file in the root backend directory and add your API keys:
```env
NESSIE_API_KEY=your_nessie_key
GEMINI_API_KEY=your_gemini_key

```


4. Run the FastAPI server:
```bash
uvicorn main:app --reload

```


5. *(Optional)* Expose the local server using Cloudflare Tunnels:
```bash
cloudflared tunnel --url http://localhost:8000

```



### Frontend Setup

1. Open the `Bankery.xcodeproj` in Xcode.
2. In your `FinanceViewModel` (or equivalent network manager), update the base URL to point to your local FastAPI server or your Cloudflare Tunnel HTTPS endpoint.
3. Build and run the project on the iOS Simulator or a physical device.

## Author

**Emily Jon** 

**Florence Cheung** 

**Cassy Moise**

**Yazmin Lopez-Munoz**
