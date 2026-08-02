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
- **2026-08-03 — checkmate-detection bug fix, still v1.0.1 but build 3→4.** While
  fixing a user-reported false-checkmate bug in the sibling ChineseChess app (this
  engine's fork source), found the identical bug here: `Board.isInCheck`'s horse check
  pattern had every blocking-leg offset sign-inverted — copy-pasted verbatim from
  Xiangqi along with the rest of the fork. Verified via a from-scratch Python
  ground-truth harness (reverse-lookup: does any enemy piece's real move list contain
  the king's square) cross-validated over 300 random games: **121 divergences** before
  the fix (worse than Xiangqi's 49/500 — Janggi horses have no river to slow their
  approach to the enemy general, so they reach checking range faster), **0** after.
  Independently re-verified the Janggi-specific elephant-check pattern (Xiangqi has no
  equivalent — Xiangqi elephants never cross the river so can never check) is correct,
  0 mismatches. v1.0.1 (build 3) was still `WAITING_FOR_REVIEW` and unreleased —
  canceled that reviewSubmission (`PATCH canceled:true`, freed the version per
  `[[asc-resubmit-after-rejection]]`), bumped to build 4, archived/exported/uploaded.
  Build processed to `VALID`, attached to version `f7295b99-7ef2-46a9-af47-4d11cb0cfa2c`
  (still `1.0.1` — no marketing-version bump needed since 1.0.1 was never released),
  new reviewSubmission `cf6bde51-4972-4f2d-8632-93914b307aad` created and submitted
  clean (no IAP/locale snags this time). **🟢 SUBMITTED, WAITING_FOR_REVIEW (2026-08-03,
  build 4).**
- **2026-08-02 — 🟢 LIVE since 2026-07-18 (v1.0.0). v1.0.1 (build 3) SUBMITTED,
  WAITING_FOR_REVIEW.** Bug found + fixed this session: despite the 2026-07-18 note
  below claiming the IAP was bundled into the original submission, it actually never
  was — `janggi.pro` sat at `READY_TO_SUBMIT` since launch (same root cause as Sam
  Loc/Klotski/Fanorona/Hanafuda/Mythsmith this same week, see
  `[[feedback_iap_must_ride_with_first_version_submission]]`). Confirmed via a fresh
  API check: both original review submissions only referenced the app version, never
  the IAP. Fixed by bumping to v1.0.1, ticking the IAP into a new draft submission via
  the ASC web UI, attaching the new version via API, and submitting both together.
- **2026-07-18 — v1.0 (build 1) SUBMITTED, WAITING_FOR_REVIEW.** Both the app version and the Janggi Pro Unlock IAP were bundled into one reviewSubmission and submitted together (confirmed via API: `appStoreState: WAITING_FOR_REVIEW`) — **this claim was wrong, see the 2026-08-02 entry above.**
- Blockers hit and fixed during submission: (1) app name collision — "Janggi - Korean Chess" was taken/reserved, "Janggi - Korean Chess AI" went through; (2) creating an `inAppPurchaseVersions` resource via the API auto-spun-up an orphaned version-less reviewSubmission draft that silently claimed the IAP twice — freed both times via `DELETE /v1/reviewSubmissionItems/{id}` (same trap as Fence AI, but triggered by API-side creation rather than the ASC-UI "tick from the IAP's own page" mistake); (3) the Korean locale needed its own Privacy Policy URL and Support URL (real Korean-language pages, not just the English ones with a URL filled in) plus the app-level Content Rights declaration, none of which are gated identically to en-US.
- Rules engine hand-verified via a standalone test harness (general starting positions, palace diagonal moves incl. blocking by own guardians, cannon screen requirement incl. the zero-legal-moves-at-start case, soldier sideways-from-start, elephant hobbling, check detection) — all passed.
- Simulator + device builds both pass clean (`rebuild.sh`); Release archive + export + altool upload succeeded, build processed to `VALID` and attached to appStoreVersion 1.0.
- Visually verified via DEBUG `JG_CAPTURE` screenshots: continuous board (no river), palace X-diagonals both ends, octagonal pieces, Han=red/Cho=blue coloring, correct hanja, Pass button, "Cho's turn" turn indicator, scripted opening sequence executes cleanly.
- App icon refined to a bold octagon+漢 emblem (was a quick placeholder).
- ASC app created manually (name collision on the first attempt — "Janggi - Korean Chess" was taken/reserved; **"Janggi - Korean Chess AI"** went through). App ID `6792245733`.
- Bundle ID `com.quyenngo.janggi` registered (ASC bundle record `3Y7BXFVMVU`).
- Legal pages live: `qngo9871-cmyk/janggi-legal` → https://qngo9871-cmyk.github.io/janggi-legal/ (privacy/terms/support/index, all verified 200).
- Full ASC metadata pushed for **both en-US and ko locales** (name/subtitle/keywords/description/promo — see `docs/asc-metadata.md`), categories (Games → Board + Strategy), age rating (all-clear → confirmed **4+**, Korea age rating auto-computed as **ALL** — no separate GRAC filing needed, confirming the earlier research).
- IAP `com.quyenngo.janggi.pro` (non-consumable, $1.99) created with en-US + ko localizations and pricing; App Store version + IAP review screenshots uploaded.
- Copyright and App Review contact set on the version.
- App confirmed available in Korea specifically (KOR automatic price point exists) — not Korea-exclusive, standard ~175-territory availability.

**Two manual steps still needed before Submit (both UI-only, no API path exists):**
1. **App Privacy nutrition labels** — must be filled in the ASC web UI (no data collected — should be a quick "no" pass).
2. **Tick the IAP into this version, from the version's own page** (App Store version → "In-App Purchases and Subscriptions" section) — **never from the IAP's own page**, that creates an orphaned draft that can never be submitted (this exact trap hit Fence AI). Also worth double-checking the visionOS/iPhone-on-Mac availability toggles are unticked (both default ON).

Once those two are done, Submit for Review is the only remaining step.

**Known follow-up, not a blocker**: the IAP review screenshot shows "Unable to load purchase option" rather than a live $1.99 price — StoreKit sandbox testing needs either a signed-in sandbox tester or an Xcode-attached local StoreKit session, neither of which CLI-only tooling can set up. Cosmetic only; can be replaced with a cleaner capture later if desired.

## Identity
- **Bundle ID:** `com.quyenngo.janggi` (ASC bundle record `3Y7BXFVMVU`)
- **Team ID:** `SM99L22Q84`
- **ASC App ID:** `6792245733`
- **App Store title:** "Janggi - Korean Chess AI" (the plain "Janggi - Korean Chess" name was rejected by ASC as a collision/reserved name)
- **KR-locale title:** "장기 - Korean Chess"
- **appStoreVersion (1.0) ID:** `bb50d61e-ca3b-494b-866e-66548aeb65ae`
- **Build 1 ID:** `41589bd4-cca9-47d3-8be3-76d4957bc932` (state VALID, attached to the version)
- **IAP product ID:** `com.quyenngo.janggi.pro` (non-consumable, $1.99, same Pro-unlock pattern as ChineseChess: Medium/Expert AI + Play vs Friend)
- **IAP ASC ID:** `6792246555`
- **Primary locale:** en-US; secondary locale: ko
- **Categories:** Games (primary), Board + Strategy (subcategories)

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
