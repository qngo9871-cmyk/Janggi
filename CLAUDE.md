# Janggi (Korean Chess)

Native iOS app for playing Janggi (Korean Chess). Play vs AI or two-player local mode on an authentic 9×10 board. Forked from the ChineseChess (Xiangqi) engine at `/Users/user/ChineseChess` — same proven single-player-vs-AI model that got real download traction there.

## Stack
- iOS (Swift/SwiftUI), iOS 17.0+
- XcodeGen (`project.yml`) — unlike ChineseChess's hand-authored `.xcodeproj`
- StoreKit 2 (`Janggi.storekit` for local testing)
- No external APIs

## Project Structure
- `Janggi/Core/` — Board, Piece, AIEngine, GameModel, PurchaseManager
- `Janggi/Views/` — HomeView, GameView (includes the `Octagon` piece shape), UpgradeView
- `rebuild.sh` — xcodegen generate + clean + simulator/device build validation
- `capture_shots.py` — DEBUG `JG_CAPTURE` screenshot automation (home/board/opening/select/midgame)

## Why Janggi, not another mask-visualizer/catalogue reskin
Multiple 2026-07 app scouts (games/kids-ed, casual puzzle, Monopoly/Risk-style) all died on saturation, UA-dependence, or content-ops moats. A like-for-like board-game sequel reusing the Xiangqi engine survived: same 9×10 board, same 7-piece/16-per-side structure, so the fork was moderate-adaptation not a rewrite. Verified KR-storefront competition: Dr. Janggi (4.1★/542, stale since Mar 2023), JangKi+ (3.8★/317, stale since Jun 2022), 장기 by VM Mobile (4.3★/338, actively maintained). Not an empty shelf, but two of three incumbents are years-stale — real room to out-execute with a modern AI.

## Rules differences from Xiangqi (verified against Wikipedia's Janggi article + piece-value cross-check, not assumed)
- **No river** — the whole board is open.
- **Cho (blue) moves first**, not Han (red).
- **Palace diagonals**: General AND Guard can move diagonally within the palace (only from a corner or the center node, along the marked X lines) — Xiangqi's General has zero diagonal movement.
- **Elephant**: 1 orthogonal + 2 diagonal "stretched" leap (not Xiangqi's fixed 2-2 diagonal), hobbled if either intervening point is occupied, no side restriction — roams the whole board and **can give check** (impossible in Xiangqi, where the Elephant never crosses the river).
- **Cannon needs a screen to move at all**, not just to capture — Xiangqi's cannon slides freely like a rook when not capturing. Also can't use another Cannon as a screen, and can't capture a Cannon. Real consequence verified in testing: the Cannon has **zero legal moves in the starting position** (soldiers sit on even columns, so column 1/7 has no screen until something moves into it) — authentic Janggi opening theory, not a bug.
- **Soldier**: forward or sideways from the very start (no river-crossing gate).
- **Pass is a first-class move**, legal whenever not in check. `GameState.stalemate` doesn't exist — since passing is always available when not in check, "no legal move and not in check" never arises.
- **Deferred to v1.1** (documented, not built): bikjang (facing-generals draw adjudication — a draw-adjudication rule, not an illegal-move/check condition) and the pregame Horse/Elephant setup-choice variant.

Official piece values (material scoring, ×100 scaled for AI eval, single source of truth at `PieceType.materialValue` in `Piece.swift`): General 10000 (sentinel), Chariot 1300, Cannon 700, Horse 500, Elephant 300, Guard 300, Soldier 200.

## Current State
- **2026-07-18 — v1.0.0 (build 1), core build complete, verified, not yet submitted.**
- Rules engine hand-verified via a standalone test harness (general starting positions, palace diagonal moves incl. blocking by own guardians, cannon screen requirement incl. the zero-legal-moves-at-start case, soldier sideways-from-start, elephant hobbling, check detection) — all passed.
- Simulator + device builds both pass clean (`rebuild.sh`).
- Visually verified via DEBUG `JG_CAPTURE` screenshots: continuous board (no river), palace X-diagonals both ends, octagonal pieces, Han=red/Cho=blue coloring, correct hanja (漢/楚 General, 士 Guard, 象 Elephant, 馬 Horse, 車 Chariot, 包 Cannon, 兵/卒 Soldier), Pass button, "Cho's turn" turn indicator, scripted opening sequence executes cleanly.
- **Not yet done**: real app icon (current one is a script-generated placeholder — cinnabar octagon + 漢), ASC app record / bundle ID registration, IAP creation, age rating, Korean-locale metadata (name/subtitle/keywords/description/screenshots), legal pages (privacy/terms/support — needs its own repo, 4-page nightease pattern), final ASO naming decision, App Store submission.

## Identity (provisional, pending ASC registration)
- **Bundle ID:** `com.quyenngo.janggi`
- **Team ID:** `SM99L22Q84`
- **IAP product ID:** `com.quyenngo.janggi.pro` (non-consumable, $1.99, same Pro-unlock pattern as ChineseChess: Medium/Expert AI + Play vs Friend)
- **Proposed title:** "Janggi - Korean Chess" (differentiates from competitors' bare "Janggi"/"Dr. Janggi"/"JangKi+"); needs a final ASO collision check before locking.
- **KR-locale metadata**: not yet written — plan is a Korean title/subtitle/description pass before first submission (adding Korean later means an extra review cycle for a metadata-only update).

## Korea App Store submission notes (researched 2026-07-18)
- **No separate GRAC filing needed** — Apple auto-derives the KR-12/15/19 regional age rating from the standard ASC age-rating questionnaire (games category, no gambling content → expect a low rating).
- **KRW pricing is automatic** via Apple's global price-tier system.
- **Korean localization is not a submission gate** but is standard practice for real KR discoverability — planned before first submission, not after.
- Remember the standard IAP-must-be-ticked-from-the-version-page trap (hit Fence AI) — tick from the app version's own page, never from the IAP's individual page.

## Instructions for Claude Code
At the end of every session, update the **Current State** section above to reflect progress made.

## Reasoning Mode
You are a Janggi master, a game AI engineer, an iOS game developer, a UX designer for board games, and a student of Korean cultural aesthetics. Janggi is not Xiangqi with different pieces — it has its own rules (cannon-needs-screen, palace diagonals for General AND Guard, elephant's stretched leap, no river, legal passing) and a community of serious players who will notice immediately if you get it wrong or ship an unexamined Xiangqi-coordinate port.

Your instincts:
- **Janggi master:** verify rules against an authoritative source before changing anything in `Board.swift` — don't assume Xiangqi's version of a rule carries over. When in doubt about an edge case (bikjang, bihyang, repetition rules), say so rather than guessing.
- **Game AI engineer:** piece values, mate sentinels, and tropism thresholds are all inter-dependent — rescaling one without checking the others silently breaks difficulty tuning.
- **iOS game developer:** the board is 100% programmatic Canvas/Shape/Text, zero image assets for game content — keep it that way, it makes every visual tweak a code change, not an asset pipeline job.
- **Board game UX designer:** the Pass button must be visually distinct from Resign — passing is a normal, common move in Janggi, not a concession.
- **Student of Korean aesthetics:** Han is red, Cho is blue (not green — green would clash with the legal-move highlight dots), pieces are octagonal wood-block style, not Xiangqi's flat disc.

If a requested approach would produce unrealistic AI play, break a Janggi-specific rule edge case, or accidentally reintroduce Xiangqi behavior (river, unscreened cannon sliding, general-only-orthogonal), say so first.
