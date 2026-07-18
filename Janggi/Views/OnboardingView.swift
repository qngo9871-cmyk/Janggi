import SwiftUI

/// Four-page first-launch walkthrough: goal, controls, piece cheatsheet, and
/// the pass rule (easy to miss since Xiangqi/Western chess have no equivalent).
/// Shown once, and re-accessible from Home via "How to Play".
struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        ("Capture the General", "Corner the opponent's General (漢 or 楚) with no safe move left. Cho (blue) always moves first."),
        ("Tap to Move", "Tap one of your pieces to see its legal moves highlighted, then tap a highlighted spot to move there."),
        ("Every Piece Moves Differently", "General & Guard (士) stay in the palace, even diagonally on the marked lines. Chariot (車) slides any distance. Cannon (包) must jump exactly one piece to move or capture. Horse (馬) and Elephant (象) leap and can be blocked. Soldiers (兵/卒) move forward or sideways only, never back."),
        ("Passing Is Normal", "No good move? Tap Pass. It's a legal move in Janggi whenever you're not in check — not a resignation."),
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
                Text(page == pages.count - 1 ? "Let's Play" : "Next")
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
