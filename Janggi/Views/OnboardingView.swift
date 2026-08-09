import SwiftUI

/// Four-page first-launch walkthrough: goal, controls, piece cheatsheet, and
/// the pass rule (easy to miss since Xiangqi/Western chess have no equivalent).
/// Shown once, and re-accessible from Home via "How to Play".
struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        (L("onboarding.page1.title"), L("onboarding.page1.body")),
        (L("onboarding.page2.title"), L("onboarding.page2.body")),
        (L("onboarding.page3.title"), L("onboarding.page3.body")),
        (L("onboarding.page4.title"), L("onboarding.page4.body")),
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(pages[page].title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(pages[page].body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            Button(action: advance) {
                Text(page == pages.count - 1 ? L("onboarding.lets_play") : L("onboarding.next"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 36)
            .padding(.bottom, 50)
        }
        .animation(.easeInOut, value: page)
    }

    private func advance() {
        if page < pages.count - 1 {
            page += 1
        } else {
            onFinished()
        }
    }
}

#Preview { OnboardingView(onFinished: {}) }
