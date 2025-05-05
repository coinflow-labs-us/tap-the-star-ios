import SwiftUI

class GameState: ObservableObject {
    @Published var credits: Int = 3
    @Published var score: Int = 0
    @Published var starPosition: CGPoint = CGPoint(x: 150, y: 300)
    @Published var showBuyModal: Bool = false
    @Published var toastMessage: String? = nil
    @Published var isStarPressed: Bool = false
}

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(Color.green.opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 8)
            .padding(.top, 50)
    }
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var gameState: GameState

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.85, blue: 1.0)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("⭐️ Tap the Star!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Spacer()
                    Text("Credits: \(gameState.credits)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .padding([.top, .horizontal])

                HStack {
                    Text("Score: \(gameState.score)")
                        .font(.headline)
                        .foregroundColor(.pink)
                    Spacer()
                }
                .padding(.horizontal)
                Spacer()

                // Show star if credits > 0
                if gameState.credits > 0 {
                    GeometryReader { geo in
                        ZStack {
                            // Star button
                            Image(systemName: "star.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.yellow)
                                .position(gameState.starPosition)
                                .scaleEffect(gameState.isStarPressed ? 0.95 : 1.0)
                                .opacity(gameState.isStarPressed ? 0.5 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.1), value: gameState.isStarPressed
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            gameState.isStarPressed = true
                                        }
                                        .onEnded { _ in
                                            gameState.isStarPressed = false
                                            // Move star to random position
                                            let width = geo.size.width
                                            let height = geo.size.height
                                            let newX = CGFloat.random(in: 60...(width - 60))
                                            let newY = CGFloat.random(in: 120...(height - 60))
                                            gameState.starPosition = CGPoint(x: newX, y: newY)
                                            gameState.score += 1
                                            gameState.credits -= 1
                                            if gameState.credits == 0 {
                                                gameState.showBuyModal = true
                                            }
                                        }
                                )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 400)
                } else {
                    Spacer().frame(height: 400)
                }
                Spacer()

                // Buy Coins Button (visible only if credits == 0)
                if gameState.credits == 0 {
                    Button(action: {
                        gameState.showBuyModal = true
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            Text("Buy Coins")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink, Color.orange]
                                ),
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(20)
                        .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 6)
                    }
                    .padding(.bottom, 40)
                }
            }

            if let toast = gameState.toastMessage {
                VStack {
                    ToastView(message: toast)
                    Spacer()
                }
                .transition(.move(edge: .top))
                .animation(.easeInOut, value: gameState.toastMessage)
            }
        }
        .sheet(isPresented: $gameState.showBuyModal) {
            VStack(spacing: 30) {
                Text("You're out of credits!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Text("Buy more coins to keep playing.")
                    .font(.headline)
                    .foregroundColor(.gray)
                Button(action: {
                    gameState.showBuyModal = false
                    goToCheckoutPage()
                }) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        Text("Buy 500 Coins")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink, Color.orange]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 6)
                }
                Button("Cancel") {
                    gameState.showBuyModal = false
                }
                .foregroundColor(.gray)
            }
            .padding(40)
        }
        .onChange(of: gameState.toastMessage) { old, new in
            if new != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        gameState.toastMessage = nil
                    }
                }
            }
        }
    }

    private func getOwnIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                    let addr = UnsafeRawPointer(interface.ifa_addr).assumingMemoryBound(
                        to: sockaddr_in.self)
                    address = String(cString: inet_ntoa(addr.pointee.sin_addr))
                }
                ptr = interface.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }

    private func getCheckoutURLFromDummyServer() -> String {
        let apiUrl = "https://api-sandbox.coinflow.cash"
        let apiKey = "MY_API_KEY"
        let userID = "user_12345"
        let myIP = getOwnIPAddress() ?? "127.0.0.1"

        guard let url = URL(string: "\(apiUrl)/api/checkout/link") else { return "" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue(userID, forHTTPHeaderField: "x-coinflow-auth-user-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "subtotal": [
                "currency": "USD",
                "cents": 5000,
            ],
            "standaloneLinkConfig": [
                "callbackUrl": "testcheckout://checkout-complete",
                "endUserDeviceIpAddress": myIP,
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var checkoutLink: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            guard let data = data, error == nil else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let link = json["link"] as? String
            {
                checkoutLink = link
            }
        }.resume()

        semaphore.wait()
        return checkoutLink ?? ""
    }

    private func goToCheckoutPage() {
        let checkoutUrlStr = getCheckoutURLFromDummyServer()
        let checkoutUrl = URL(string: checkoutUrlStr)!
        DispatchQueue.main.async {
            openURL(checkoutUrl)
        }
    }
}

/// Preview Notice:
/// Redirects will not work in the preview, but will work in the simulator.
/// *
struct ContentView_Previews: PreviewProvider {
    static let gameState = GameState()
    static var previews: some View {
        ContentView()
            .environmentObject(gameState)
    }
}
