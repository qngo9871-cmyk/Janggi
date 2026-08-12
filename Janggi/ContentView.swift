import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        #if DEBUG
        if let capture = ProcessInfo.processInfo.environment["JG_CAPTURE"] {
            if capture == "onboarding" {
                return AnyView(OnboardingView(onFinished: {}))
            }
            // Any other capture value (including "home") bypasses onboarding
            // so HomeView's own JG_CAPTURE handling (paywall/board/opening/etc.)
            // still fires. Previously "home" was excluded from this bypass and
            // fell through to the hasSeenOnboarding check below — on a fresh
            // install (hasSeenOnboarding defaults false), that meant the
            // capture script's "01-home" shot actually captured the
            // onboarding screen instead of Home. Confirmed via screenshot on
            // a freshly-created dedicated simulator (2026-08-12 polish pass).
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
