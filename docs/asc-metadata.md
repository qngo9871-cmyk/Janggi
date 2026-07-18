# Janggi - Korean Chess — App Store Connect metadata

Drafted per `~/.claude/skills/app-store-submission/references/metadata-template.md`. Ready to push via API once the ASC app listing exists (blocked on manual creation — see CLAUDE.md).

## en-US (primary locale)

**App Name (≤30):** `Janggi - Korean Chess` (21 chars)

**Subtitle (≤30):** `Outsmart a sharp AI opponent` (28 chars)

**Keywords (≤100, comma-separated no spaces):**
`jangki,strategy,board game,two player,offline,tabletop,brain training,general,cannon,solo,puzzle` (96 chars)

**Description:**
```
Janggi is Korean chess, played against a sharp on-device AI or a friend on the same phone.

Every move follows the real rules — cannons that need a screen to fire, generals and guards sliding along the palace's marked diagonals, elephants leaping clear across the open board. No ads interrupt a game, and no subscription is ever required.

• Test yourself — three AI difficulty levels, from a forgiving Beginner to a sharp Expert
• Play together — pass-and-play two-player mode, no account needed
• Learn as you go — tap any piece to see every legal move highlighted
• Play anywhere — fully offline, no internet connection required
• Keep it simple — one unlock, no subscription, no ads

Set up the board and play your first game today.
```

**Promotional Text (≤170):**
`Authentic Janggi (Korean Chess) with three AI difficulty levels and full offline pass-and-play two-player mode. No subscription, ever.`

**Support URL:** https://qngo9871-cmyk.github.io/janggi-legal/support.html
**Marketing URL:** https://qngo9871-cmyk.github.io/janggi-legal/
**Privacy Policy URL:** https://qngo9871-cmyk.github.io/janggi-legal/privacy.html
**Copyright:** © 2026 Quyen Ngo

---

## ko (Korean locale — targets the KR storefront)

**⚠️ Native-speaker sanity check recommended before final lock** — this is a solid draft, not verified by a native Korean speaker. Given the whole point of this locale is real KR-market authenticity, worth a second look before submission if Q knows someone to run it past.

**App Name (≤30):** `장기 - Korean Chess` (17 chars) — leads with the Hangul search term while keeping consistent branding with the English listing.

**Subtitle (≤30):** `날카로운 AI를 이겨보세요` (14 chars) — "Try to beat a sharp AI."

**Keywords (≤100):**
`보드게임,전략게임,두뇌게임,오프라인,혼자하는게임,두명이서,고전게임,대국,인공지능` (~48 chars)
(board game, strategy game, brain game, offline, solo game, two-player, classic game, match, AI)

**Description:**
```
장기를 날카로운 인공지능과, 또는 같은 휴대폰으로 친구와 마주 앉아 즐겨보세요.

모든 규칙을 정확하게 구현했습니다 — 포는 반드시 다른 기물을 넘어야만 움직일 수 있고, 궁과 사는 궁성에 그려진 대각선을 따라 이동할 수 있으며, 상은 강을 건너지 않고 넓은 판 전체를 가로지르는 큰 걸음으로 움직입니다. 광고로 게임이 끊기지 않고, 구독도 전혀 필요 없습니다.

• 실력을 시험해보세요 — 초급부터 고급까지 3단계 난이도
• 함께 즐기세요 — 계정 없이 같은 기기에서 즐기는 2인 대국 모드
• 배우면서 즐기세요 — 기물을 누르면 가능한 모든 수가 표시됩니다
• 어디서나 즐기세요 — 인터넷 연결 없이 완전히 오프라인으로 작동합니다
• 간단하게 — 한 번의 구매로 끝, 구독도 광고도 없습니다

지금 바로 첫 대국을 시작해보세요.
```

**Promotional Text (≤170):**
`정통 장기를 3단계 AI 난이도와 오프라인 2인 대국 모드로 즐겨보세요. 구독 없이 한 번의 구매로 끝.`

**Privacy Policy URL (ko):** https://qngo9871-cmyk.github.io/janggi-legal/privacy-ko.html
**Support URL (ko):** https://qngo9871-cmyk.github.io/janggi-legal/support-ko.html
**Marketing URL (ko):** https://qngo9871-cmyk.github.io/janggi-legal/

Dedicated Korean-language legal pages (not just the en-US pages with a URL field filled) — ASC's per-locale requirement was initially satisfied with the English pages, but a Korean user landing on an English-only privacy policy is a real gap, not just a form technicality. `terms-ko.html` also exists (linked from the English `terms.html`) even though ASC has no separate per-locale Terms field to point at it.

---

## Age rating

Abstract board game, no violence/gambling/mature content/user-generated content/web browser. Every questionnaire answer should be "None" — expect **4+**.

## IAP

- Product ID: `com.quyenngo.janggi.pro`
- Type: Non-consumable
- Price: $1.99 USD (Tier matching existing ChineseChess pattern)
- Display name: "Janggi Pro Unlock"
- Description (≤55 chars per `feedback_iap_description_limit`): `Unlock Medium/Expert AI + Play vs Friend` (41 chars)

## Copyright / review contact
- Copyright: © 2026 Quyen Ngo
- Review contact: qngo@icloud.com / +61425409937 (per `user_app_review_contact` — not gmail, for com.quyenngo.*)
- `usesNonExemptEncryption`: NO (baked into Info.plist via project.yml)
