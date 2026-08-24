## Status 2026-08-24 — DEBUG isPro double-gating bug fixed, code-only, NOT YET submitted

Found by the fixed portfolio-wide `~/asc-tools/compliance_gate.py`: `isPro = JG_CAPTURE !=
"paywall"` defaulted to unlocked on a bare Debug run and on the "home" capture (both `!=
"paywall"`), same bug already fixed elsewhere in the portfolio. Fixed to also exclude
"home" explicitly. **Code fixed and committed only — deliberately not built/archived/
uploaded/submitted yet**, staged for a future day per the staggered-submission pacing (see
memory `project_20260824_debug_gating_submission_queue`). Next: bump version, archive,
upload, `new_version.py`, submit.

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

**2026-08-20 — v1.0.4 SUBMITTED, WAITING_FOR_REVIEW** (superseding the earlier
2026-09-03 staggered-slot plan below — the user gave explicit go-ahead
2026-08-20 to ship the apps that were already live with the free-forever bug,
Janggi included). The stuck `1.0.1` submission (`f7295b99-...`, `REJECTED`
version item + an IAP item, state `UNRESOLVED_ISSUES`) was canceled via the
API to free the version; bumped in place to **1.0.4**, build 7 (Delivery UUID
`c3615186-1085-4eaf-922e-420f34b0683e`, `VALID`) attached, `whatsNew` set for
both en-US/ko. Canceling reset the IAP to `READY_TO_SUBMIT`, so the user
manually re-ticked it into the version via the ASC web UI, which created its
own new draft reviewSubmission (`52ec7922-...`) — attached the version to
that same draft rather than creating a competing one, then submitted.
Verified post-submit that both the version and the IAP moved to
`WAITING_FOR_REVIEW` together.

**2026-08-18 — v1.0.4 (build 7) archived, exported, and uploaded to App Store
Connect (Delivery UUID `c3615186-1085-4eaf-922e-420f34b0683e`), processed to
`VALID`. This is the trial-paywall build described just below. Bumped past
both the local 1.0.3(6) and the existing ASC version 1.0.1 (REJECTED,
`f7295b99-...`) so the number can't collide with any version already known to
ASC. NOT YET submitted for review, and the build is not attached to any
appStoreVersion — deliberately held per the portfolio-wide staggered
resubmission plan (this app's own slot is 2026-09-03, see the "Build staged
for resubmission" entry below) and the explicit instruction to wait for the
user's go-ahead app by app so Apple doesn't see a batch of near-simultaneous
submissions.**

**2026-08-18 — 7-day trial, then everything locks (no permanent free tier).** Part of the
portfolio-wide standing rule that no app should offer free play at any difficulty/mode
forever, only a capped trial (the ChineseChess/SamLoc pattern, applied here next).
Previously **Beginner AI difficulty was permanently free** — `AIDifficulty.requiresPro`
returned `false` for `.beginner` and `true` for `.medium`/`.expert`, with "Play vs Friend"
always Pro-gated. `PurchaseManager.swift` gained `trialActive`/`trialDaysRemaining` backed
by a `firstLaunchDate` UserDefaults key (7-day `trialDuration`), plus
`evaluateTrialStatus()` called from `init()` alongside the existing transaction listener —
existing installs with no stored `firstLaunchDate` get the clock started by this update
rather than being locked out immediately. `HomeView` replaced its two inline
`level.requiresPro && !purchaseManager.isPro` checks with a single `isLocked(_:)`: Medium/
Expert stay permanently Pro-only (unaffected by the trial, matching what was already
gated), but **Beginner now locks too once the 7-day trial ends** — so no difficulty stays
free forever. Added a trial-days caption (`home.trialdays`, e.g. "Free trial — 5 day(s)
left") shown while the trial is active and not Pro, plus a Home footnote button and
`UpgradeView` subtitle that both switch to "trial ended" copy (`home.upgrade.trialended`,
`upgrade.subtitle.trialended`) once expired. New keys added to both `en.lproj` and
`ko.lproj` `Localizable.strings` (hand-translated Korean, matching the existing formal
register). `PurchaseManager.updateEntitlementStatus()`'s `#if DEBUG` block was already
double-gated (`isPro = ProcessInfo...environment["JG_CAPTURE"] != "paywall"`, not a bare
`isPro = true`), so left untouched per the standing DEBUG-gating rule — no bug present
here. Build-verified: `xcodebuild -destination 'generic/platform=iOS' -configuration
Debug build` → **BUILD SUCCEEDED**. **Not yet archived/submitted — this is a real
product change for existing live users (and this app is separately mid-way through the
staggered Guideline 5.6 resubmission below), holding for explicit go-ahead before any
archive/export/upload/submit step.**

## Build staged for resubmission (2026-08-13)

Archived, exported, and uploaded a Release build ahead of the staggered resubmission — still
blocked until 2026-08-18 by the Guideline 5.6 account-level hold, this app resubmits
**2026-09-03** (batch 6). Build **1.0.3 (6)** uploaded via
`xcrun altool --upload-app` (Delivery UUID `ae6eacdb-a527-4af8-8fe6-2f6d83bb9362`), processed to `VALID` by Apple, and
attached to the existing `REJECTED` appStoreVersion (id `f7295b99-7ef2-46a9-af47-4d11cb0cfa2c`) via a direct
`PATCH appStoreVersions/{id}/relationships/build` API call — independently re-verified via a
follow-up `GET` on the same relationship, not just trusted from the PATCH's 204 response.

**Deliberately NOT done yet** — waiting for the user's explicit go-ahead on this app's
scheduled date, per the staggered resubmission plan:
1. Tick the Pro IAP into this version in the App Store Connect **web UI** — the API has no
   way to do this; it must be done from the version's own page (not the IAP's own page, which
   creates an orphaned draft submission — a mistake this portfolio hit once before).
2. Submit for review.

- **2026-08-12 — second (deeper) polish pass, batch 6 (resubmits 2026-09-03).
  Local + ASC metadata/screenshots only — no build uploaded, no
  review-submission touched, per the hard "don't submit" constraint.**
  🟡 **READY FOR RESUBMISSION 2026-09-03** (staggered schedule, do not
  submit early).
  - **Localization re-verification (this session's highest-stakes check,
    same rigor as Tiến Lên's card-back check):** confirmed real, not
    regressed.
    1. Diffed the sorted key sets of `en.lproj/Localizable.strings` (48
       keys) vs `ko.lproj/Localizable.strings` (48 keys) — **byte-identical
       key sets, zero diff.**
    2. Grepped every `L("...")` call site across `Janggi/Views` and
       `Janggi/Core` (48 unique keys used) and confirmed every one resolves
       to a real string in both `.lproj` files — zero missing keys either
       direction.
    3. **Switched the running app's language live in the Simulator**
       (`-AppleLanguages`/`-AppleLocale`, both `en`/`en_US` and `ko`/`ko_KR`)
       and screenshotted four separate screens — onboarding, Home, in-game
       (turn indicator + New Game/Pass/Resign), and the paywall — confirming
       the UI text actually changes correctly in both languages at every
       depth, not just onboarding. E.g. "Cho's turn"/"초 차례",
       "New Game/Pass/Resign"/"새 게임/패스/기권", "Beginner/Medium/Expert"/
       "초급/중급/고급", paywall "Unlock Full Version"/"전체 버전 잠금 해제". **No
       gaps found — the 2026-08-09 localization work held up completely.**
  - **Horse-check sign-fix re-verification:** independently hand-traced all
    8 `Board.isInCheck` horse-check offset pairs against `horseMoves`' own
    move-generation offsets (not just re-reading the prior claim) — every
    pair's blocking-leg offset correctly derives from the horse's own
    position, confirming the 2026-08-03 fix is still intact. No regression.
  - **Real bug found and fixed: `01-home.png` (the App Store hero
    screenshot) was actually capturing the onboarding screen, not Home.**
    Root cause: `ContentView.swift`'s `#if DEBUG` block excluded
    `JG_CAPTURE == "home"` from the onboarding bypass, so on a **freshly
    installed app** (a fresh dedicated simulator, `hasSeenOnboarding`
    defaults `false`) that specific capture value fell through to the
    normal `!hasSeenOnboarding` check and showed onboarding instead of
    Home. Confirmed via screenshot before the fix (showed "Capture the
    General" onboarding page 1, not the Home screen), fixed by removing the
    `capture != "home"` exclusion, rebuilt, recaptured, and reconfirmed —
    `01-home.png` now correctly shows Home with the current version stamp
    (`v1.0.2 (5)` → now `v1.0.3 (6)` after this session's bump). This is
    the kind of bug that stays invisible on a reused/warm simulator (where
    onboarding was already dismissed) and only surfaces on a clean device —
    exactly the scenario the batch's "always use a dedicated simulator"
    rule creates, so worth remembering for every future capture run.
  - **Stale screenshots fixed:** `screenshots/v2/*.png` were captured under
    v1.0.0 build 1 — predated the checkmate fix, the localization work, and
    the captured-material tray (all from 2026-08-09). Recaptured all 5 on a
    freshly created dedicated `Janggi-Capture` simulator device (not a
    shared/generic name) to avoid the cross-app contamination other apps in
    this batch hit; visually inspected every one, all correctly show
    current app state.
  - **UI polish check:** examined the `GameView` board layout (the
    GeometryReader-centered board leaves a visible gap above/below the
    board on tall screens) against the "top-hugging VStack / one-sided dead
    space" bug pattern flagged elsewhere in this batch — measured
    pixel-precise via the actual screenshot (top margin ~456px, bottom
    margin ~335px out of a 2868px-tall capture) and concluded this is
    legitimate GeometryReader centering, not the one-sided bug pattern seen
    in Surakarta/Omweso. No fix made — verified, not invented.
  - **`capture_shots.py` fixed:** `APP_DIR` was still hardcoded to the old
    MacBook Air path (`/Users/user/Janggi`) — now resolves relative to the
    script's own location. `find_device()` used to grab any available
    "iPhone ... Pro Max" simulator by pattern match, which risks the
    shared-simulator contamination bug that hit other apps this batch
    (concurrent capture scripts writing to the same device) — now targets
    (and creates if missing) a dedicated `Janggi-Capture` device by name.
  - **`asc_push_janggi.py` bugs found and fixed** (read through before
    trusting it, per house process):
    - `find_editable_appinfo` read the wrong attribute key entirely
      (`"state"` instead of the real `"appStoreState"`), so its editable-
      state check never matched anything and it always fell through to
      `infos[0]` — which order isn't guaranteed to be the editable one.
    - `find_or_create_version` matched on a hardcoded
      `versionString == "1.0"` — since v1.0 is the **live, READY_FOR_SALE**
      version and v1.0.1 is the editable REJECTED one, this would have
      silently pushed metadata onto the already-shipped live version
      instead of the draft. Fixed to select the highest-versioned
      non-locked (`READY_FOR_SALE`/`PENDING_DEVELOPER_RELEASE`/
      `PROCESSING_FOR_APP_STORE`) version by real `appStoreState`.
    - The version-creation fallback path hardcoded `releaseType: "MANUAL"`
      instead of the house standard `AFTER_APPROVAL`.
    - Verified the fix against the live API before trusting it: dry-run
      confirmed `find_editable_appinfo` → `744cb3d8-...` (the REJECTED
      appInfo) and `find_or_create_version` → `f7295b99-...` (the REJECTED
      v1.0.1), not the READY_FOR_SALE ones.
  - **`asc_push_janggi_screenshots.py` bugs found and fixed:**
    - `SHOTS_DIR` hardcoded to `/Users/user/Janggi/screenshots/v2` (same
      stale MacBook Air path) — now resolves via `Path.home() / "Projects" /
      "Janggi" / ...`.
    - `find_version_loc_id` had the identical hardcoded-`"1.0"` version-
      selection bug as the metadata script — fixed the same way.
    - `upload_iap_review_screenshot` had no error handling — a locked/
      in-review IAP (409) would crash the whole script even after the 5
      version screenshots already uploaded successfully. Added a
      try/except; confirmed it fires for real (the IAP review screenshot
      genuinely 409'd this run — `janggi.pro` is still tied to the prior
      REJECTED submission — and the script now reports it cleanly instead
      of crashing).
  - **ASO refresh (copy was already strong — per `docs/asc-metadata.md`,
    only keywords touched):** en-US keywords swapped `tabletop`/`puzzle`
    (generic/genre-mismatched) for `changgi` (alternate English spelling)
    and `checkmate` (99/100 chars, was 96/100). ko keywords added
    `체스`/`정통장기` (chess / authentic-janggi) — plenty of headroom (52/100,
    was 44/100). Description/subtitle/promo left untouched — already
    genuinely compelling, not template filler.
  - **Pushed live to ASC** (metadata + screenshots only, no build/
    review-submission): `asc_push_janggi.py` and
    `asc_push_janggi_screenshots.py`, both re-run after the bug fixes above
    and verified via `asc_inspect_listing.py` — keywords confirmed updated
    on the REJECTED v1.0.1 (not the live v1.0), all 5 version screenshots
    confirmed uploaded.
  - **Version bump:** `MARKETING_VERSION` 1.0.2 → **1.0.3**,
    `CURRENT_PROJECT_VERSION` 5 → **6** (`project.yml`, single settings
    block — no separate target-level override to miss). Rebuilt clean on
    Simulator after the bump: **BUILD SUCCEEDED, zero warnings.**
  - **Build:** clean `xcodegen generate` + Simulator build both before and
    after this session's changes, zero warnings both times.
  - **Not touched this session:** rules engine correctness beyond the
    horse-check spot-check (already re-verified 2026-08-09, no reason to
    redo); onboarding content (already real, confirmed still gated on
    `hasSeenOnboarding`); DEBUG/isPro double-gating (already confirmed
    clean 2026-08-09, no changes touched that code path this session); IAP
    wiring.
  - **Still open / needs Q's judgment:** none blocking. The IAP review
    screenshot (`iap-review-paywall.png`, separate from the 5-shot pipeline)
    is still the old dark-mode "Unable to load purchase option" capture
    from initial submission — pre-existing known cosmetic limitation
    (StoreKit sandbox can't preview live pricing in an unattended capture),
    documented since 2026-07-18, not touched this session.
- **2026-08-09 — pre-resubmission quality review (part of the 19-app Guideline
  5.6 account-hold remediation pass; resubmission blocked until 2026-08-18).
  Local-only: nothing touched in App Store Connect.** 🟡 **READY FOR
  RESUBMISSION AFTER 2026-08-18**, pending Apple's 5.6 hold lifting.
  - **Checkmate-detection re-verification (the known-issue area for this
    session):** hand-traced all 8 horse-check offset pairs in
    `Board.isInCheck` against `horseMoves`' own offsets and confirmed the
    2026-08-03 sign fix is still intact and mathematically correct (every
    pair's blocking-leg offset matches what `horseMoves` would produce from
    the horse's own position). Independently re-verified the
    Janggi-specific elephant-check pattern the same way — also correct, no
    regression. No code change needed here; this was verification only.
  - **Build:** clean `xcodegen generate` + `xcodebuild build` for both
    Simulator and device (`generic/platform=iOS` and
    `generic/platform=iOS Simulator`) — **0 errors, 0 warnings** (the only
    log line is a benign "no AppIntents.framework dependency" notice, not a
    real warning), both before and after this session's changes.
  - **Localization — was previously a real gap, now fixed:** the app had
    *zero* in-app localization infrastructure before this session (ASC
    listing had EN + ko locales, but every UI string was a hardcoded English
    literal). Added `Janggi/Core/Localization.swift` (`L(_ key:, _ args:)`
    helper over `NSLocalizedString` + `String(format:)`) plus
    `Resources/en.lproj/Localizable.strings` and
    `Resources/ko.lproj/Localizable.strings` (60+ keys). Converted every
    user-facing string across `HomeView`, `UpgradeView`, `OnboardingView`,
    `GameView`, `PurchaseManager`, and `AIDifficulty.displayName` to route
    through `L()`. Used authentic Janggi terminology for Korean, not literal
    translation — e.g. "장군" for check, "외통수" for checkmate, "초급/중급/고급"
    for difficulty tiers, "한/초" for the side names (matching the 漢/楚 hanja
    already on the pieces). Added `knownRegions: [en, ko]` to `project.yml`.
    **Visually verified live in the iOS 17 Simulator** with
    `-AppleLanguages "(ko)" -AppleLocale "ko_KR"`: onboarding correctly
    renders "장군을 잡아라" / "다음" etc. — confirmed real runtime localization,
    not just App Store listing text. (Brand name "Janggi" / "장기 · Korean
    Chess" subtitle deliberately left as bilingual literals — that's
    intentional branding, not a localization gap.)
  - **Onboarding:** confirmed real and forced on first launch (`ContentView`
    gates on `@AppStorage("hasSeenOnboarding")`), 4 genuine content pages
    (goal, tap-to-move, per-piece movement cheatsheet, the pass rule),
    re-reachable from Home via "How to Play." No changes needed, just
    localized.
  - **DEBUG/isPro double-gating** (the recurring bug pattern flagged across
    this developer's portfolio): checked, **not present**. Single
    `@Published var isPro` source of truth in `PurchaseManager`, every
    consumer (`HomeView`, `UpgradeView`) reads the same property; the
    `#if DEBUG` override only exists to force the paywall open for
    screenshot capture (`JG_CAPTURE == "paywall"`) and doesn't leak into
    Release builds.
  - **TODO/FIXME/placeholder/dummy-text grep:** zero hits across the whole
    codebase.
  - **Genuine differentiation addition (small, per the "polish not redesign"
    guidance):** added a captured-material tray to `GameView` — each side's
    captured enemy pieces now render as small hanja glyphs above the board,
    tracked in `GameModel.capturedByCho` / `capturedByHan`. Real Janggi-
    relevant UX (material balance matters more here than in Western chess,
    no pawn promotion to offset losses), not a cosmetic reskin change.
  - **Version bump:** `MARKETING_VERSION` 1.0.1 → **1.0.2**,
    `CURRENT_PROJECT_VERSION` 4 → **5** (`project.yml`, base settings).
  - **Not touched this session** (already solid, re-verified only): rules
    engine correctness elsewhere (palace diagonals, elephant stretched leap,
    cannon screen requirement, soldier sideways-from-start, legal-pass /
    no-stalemate design) — re-read in full, no issues found; IAP wiring
    (`PurchaseManager` uses standard StoreKit 2 `Transaction.currentEntitlements`
    + `Transaction.updates` listener pattern, correct); `PrivacyInfo.xcprivacy`
    (empty collected-data array, correct for a no-network app).
  - **Still open / needs Q's judgment:** none blocking. Optional
    follow-up: the App Store screenshots (`screenshots/v2/`) predate this
    session's captured-tray addition and Korean-locale verification; not a
    functional issue since screenshots aren't user-facing app behavior, just
    worth a reshoot before the next ASC push if Q wants the marketing
    screenshots to reflect the new tray. `capture_shots.py`'s `APP_DIR` is
    still hardcoded to the old MacBook Air path (`/Users/user/Janggi`) from
    before the Mac mini migration — didn't fix since script wasn't run this
    session (see `[[mac-mini-migration-gaps]]`), but will need a path fix
    before it's next used to regenerate screenshots.
- **2026-08-07 — correction: the IAP fix never actually took, despite two prior
  claims that it did.** Re-auditing after a user question about IAP revenue
  found `janggi.pro` still `READY_TO_SUBMIT` — the build-4 reviewSubmission
  `cf6bde51-...` (created 2026-08-03, `WAITING_FOR_REVIEW` for 5 days) had
  only the version item, never the IAP, despite the 2026-08-02 and 2026-08-03
  entries below both claiming the IAP was ticked in. Cancelled `cf6bde51`
  (`PATCH canceled:true`, polled to `COMPLETE`) to free the version. **Still
  needs**: tick `Janggi Pro Unlock` into a new draft submission from the
  version's own page in the ASC web UI (never from the IAP's own page — see
  the Fence AI trap noted below), then attach v1.0.1/build 4 + submit via
  API, then verify the IAP's own state actually moves off `READY_TO_SUBMIT`
  post-submit before declaring this fixed again. See
  `[[feedback_iap_must_ride_with_first_version_submission]]` for the
  corrected account-wide record — Janggi was the one app of six where the
  "fixed" claim didn't hold up.
  **Resolved same day**: user ticked `Janggi Pro Unlock` into a new draft
  submission (`fb53811a-...`) from the version's own page; attached v1.0.1
  build 4 (`f7295b99-...`) to that same draft via API, submitted. Verified
  post-submit: `janggi.pro` moved `READY_TO_SUBMIT` → `WAITING_FOR_REVIEW`,
  genuinely part of the submission this time (not just the version alone,
  unlike the two prior failed attempts). **🟢 SUBMITTED, WAITING_FOR_REVIEW
  (2026-08-06/07), IAP genuinely included this time.**
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
