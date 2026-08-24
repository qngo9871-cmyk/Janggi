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

    /// True when `difficulty` should show a lock and route to the paywall.
    /// Medium/Expert were already Pro-only and stay that way regardless of
    /// the trial. Beginner was the permanently-free tier — it now locks too
    /// once the 7-day trial ends, so no difficulty stays free forever.
    private func isLocked(_ difficulty: AIDifficulty) -> Bool {
        if purchaseManager.isPro { return false }
        if difficulty.requiresPro { return true }
        return !purchaseManager.trialActive
    }

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
                    Picker(L("home.difficulty_picker"), selection: $selectedDifficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            HStack {
                                Text(level.displayName)
                                if isLocked(level) {
                                    Image(systemName: "lock.fill")
                                }
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 340)
                    .onChange(of: selectedDifficulty) { _, newValue in
                        if isLocked(newValue) {
                            upgradeFeature = L("home.upgrade_feature.difficulty", newValue.displayName)
                            showUpgrade = true
                        }
                    }

                    if !purchaseManager.isPro && purchaseManager.trialActive {
                        Text(String(format: L("home.trialdays"), purchaseManager.trialDaysRemaining))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if isLocked(selectedDifficulty) {
                            upgradeFeature = L("home.upgrade_feature.difficulty", selectedDifficulty.displayName)
                            showUpgrade = true
                        } else {
                            navigateToAI = true
                        }
                    } label: {
                        Label(L("home.play_vs_ai"), systemImage: "cpu")
                            .frame(maxWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                // Local two-player
                Button {
                    if !purchaseManager.isPro {
                        upgradeFeature = L("home.upgrade_feature.play_vs_friend")
                        showUpgrade = true
                    } else {
                        navigateToLocal = true
                    }
                } label: {
                    HStack {
                        Label(L("home.play_vs_friend"), systemImage: "person.2")
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
                    Text(L("home.how_to_play"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !purchaseManager.isPro {
                    Button {
                        upgradeFeature = L("home.upgrade_feature.paywall_capture")
                        showUpgrade = true
                    } label: {
                        Text(L(purchaseManager.trialActive ? "home.upgrade" : "home.upgrade.trialended"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
                        upgradeFeature = L("home.upgrade_feature.paywall_capture")
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
