import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        #if DEBUG
        if let capture = ProcessInfo.processInfo.environment["JG_CAPTURE"], capture != "home" {
            if capture == "onboarding" {
                return AnyView(OnboardingView(onFinished: {}))
            }
            // Any other capture value bypasses onboarding so HomeView's own
            // JG_CAPTURE handling (paywall/board/opening/etc.) still fires.
            return AnyView(HomeView())
        }
        if ProcessInfo.processInfo.environment["JG_SKIP_ONBOARDING"] != nil {
            return AnyView(HomeView())
        }
        #endif
        if !hasSeenOnboarding {
            return AnyView(OnboardingView(onFinished: { hasSeenOnboarding = true }))
        }
        return AnyView(HomeView())
    }
}

#Preview { ContentView() }
