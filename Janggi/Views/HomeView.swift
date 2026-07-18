import SwiftUI

/// Home screen with game mode selection.
struct HomeView: View {

    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedDifficulty: AIDifficulty = .beginner
    @State private var navigateToAI = false
    @State private var navigateToLocal = false
    @State private var showUpgrade = false
    @State private var upgradeFeature = ""
    @State private var showHowToPlay = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Title
                Text("Janggi")
                    .font(.largeTitle.bold())
                Text("장기 · Korean Chess")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Spacer()

                // AI game section
                VStack(spacing: 12) {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            HStack {
                                Text(level.rawValue)
                                if level.requiresPro && !purchaseManager.isPro {
                                    Image(systemName: "lock.fill")
                                }
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                    .onChange(of: selectedDifficulty) { _, newValue in
                        if newValue.requiresPro && !purchaseManager.isPro {
                            upgradeFeature = "\(newValue.rawValue) difficulty"
                            showUpgrade = true
                        }
                    }

                    Button {
                        if selectedDifficulty.requiresPro && !purchaseManager.isPro {
                            upgradeFeature = "\(selectedDifficulty.rawValue) difficulty"
                            showUpgrade = true
                        } else {
                            navigateToAI = true
                        }
                    } label: {
                        Label("Play vs AI", systemImage: "cpu")
                            .frame(maxWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                // Local two-player
                Button {
                    if !purchaseManager.isPro {
                        upgradeFeature = "Play vs Friend"
                        showUpgrade = true
                    } else {
                        navigateToLocal = true
                    }
                } label: {
                    HStack {
                        Label("Play vs Friend", systemImage: "person.2")
                            .frame(maxWidth: 190)
                        if !purchaseManager.isPro {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button { showHowToPlay = true } label: {
                    Text("How to Play")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("v\(version) (\(build))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationDestination(isPresented: $navigateToAI) {
                GameView(aiEngine: AIEngine(difficulty: selectedDifficulty))
            }
            .navigationDestination(isPresented: $navigateToLocal) {
                GameView()
            }
            .sheet(isPresented: $showUpgrade) {
                UpgradeView(feature: upgradeFeature)
                    .environmentObject(purchaseManager)
            }
            .sheet(isPresented: $showHowToPlay) {
                OnboardingView(onFinished: { showHowToPlay = false })
            }
            .onAppear {
                #if DEBUG
                // Screenshot capture: "paywall" opens the IAP unlock sheet directly
                // (isPro forced false for this one capture — see PurchaseManager).
                // Any other JG_CAPTURE value jumps into a local (no-AI) game so the
                // seeded board holds still. Inert in production.
                if let name = ProcessInfo.processInfo.environment["JG_CAPTURE"] {
                    if name == "paywall" {
                        upgradeFeature = "Medium & Expert difficulty, and Play vs Friend"
                        showUpgrade = true
                    } else if name != "home" {
                        navigateToLocal = true
                    }
                }
                #endif
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(PurchaseManager())
}
