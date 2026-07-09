# Walkout — Home-Screen Widget Plan

**Status:** v1 spec, ready to build
**Owner:** Product design
**Targets:** Android-first (Pixel-class test device), iOS parity notes inline
**Ground truth:** everything in this doc reads only data that exists in the repo today
(`assets/data/*.json` via `AppDataset`, favorites in Hive, Pick'Em cards in SharedPreferences).
Anything demo/simulated is explicitly flagged.

---

## 1. Design POV

**Mini experiences, not shrunken screens.** A widget earns its grid cell by answering one
question at a glance — *"how long until my guy fights?"* — not by cramming a screen into 320dp.
Every widget below has exactly one job, one dominant number or image, and one tap story.

**The brand translates cleanly to the grid:**

- **Octagon chamfer** (`OctagonBorderShape`, cut=14) is the container language. Widgets are
  chamfered dark cards, not rounded rects — instantly recognizable on a home screen full of
  rounded rects. On Android we ship the chamfer inside the pre-rendered PNG (launchers force
  their own outer corner radius; we let the system radius clip the PNG's transparent margin
  and draw our chamfer inside it).
- **Aura glow** (`AuraCard`: `surfaceElevated → surface` vertical gradient + red radial glow,
  alpha 0.12–0.22) is the surface treatment. It reads beautifully at widget scale because it's
  low-frequency — no detail to lose.
- **Anton** carries names and numbers. Condensed = big optical sizes in small cells.
  `MAKHACHEV` in Anton at 28dp fits a 2x2. Inter for metadata lines.
- **Brand red `#D20A0A`** is reserved for *time pressure and liveness* (countdown ring, LIVE
  dot, fight-week ring). **Gold `#FACC15`** is reserved for *champions and locked picks*
  (the `RankBadge` "C" convention). Never both loud at once.

**Steal / do better:**

| From | Steal | Do better |
|---|---|---|
| Box Box (F1) | The "one event, phases of a weekend" mental model; unapologetic brand typography in the widget | Box Box widgets are schedule-viewers. Ours *changes what it is* by phase (Living Widget) instead of re-skinning a table. |
| Apple Sports | Score-first hierarchy, ruthless minimalism, native text crispness | Apple Sports is generic across leagues. We go fighter-first: faces, records, corners — parasocial, not tabular. |
| Flighty | Pre-scheduled timeline entries so the widget is *already correct* when you look (phase flips at known times, zero polling) | Flighty's states are operational. Ours are emotional — the widget should feel like fight week. |
| Carrot Weather | Personality in microcopy ("PICKS LOCK IN 3H") | Keep it dry-brutal, not jokey. UFC tone, no emoji. |

**The one rule:** if a widget would be equally good as a notification, it's not a widget. Widgets
here are *standing presence* — a fighter lives on your home screen the way an album lives in
Apple Music's widget.

---

## 2. The Lineup, Ruthlessly Prioritized

### Verdict on The Living Widget

**The Living Widget IS v1, and it is the umbrella.** It is not a 16th concept — it's the
delivery vehicle for the product owner's top concepts. Concretely:

- **Fight Clock (#1)** is the Living Widget's *engine* — the phase state machine. It doesn't
  ship separately; it IS states S2–S4 below.
- **Octagon Countdown (#3)** is the Living Widget's *fight-week face* — the red-filling
  octagon ring is how S2/S3 render.
- **Face-Off (#4)** appears twice: as the Living Widget's *booked face* (S1), and as a
  standalone 4x4 art widget (different job: poster, not companion — see below).
- **Ranking Shift (bonus)** is the Living Widget's *aftermath face* (S6).

One widget, zero setup, that transforms by calendar is exactly the "companion, not a
shortcut" brief — and it's also the correct engineering play: one state machine, one
scheduler, N faces, instead of N widgets each with their own refresh logic.

### v1 — four widgets, shippable in ~4 weeks

| # | Widget | Emotional hook | Data availability | Buildability |
|---|---|---|---|---|
| 1 | **The Living Widget** (4x2 hero, 2x2 compact) | "It knows what week it is." The app's #1 selling point, embodied. | ✅ events + dates + favorites + rankings all local | Medium-hard: state machine + pre-scheduled flips. All countdown text is native (free ticks). |
| 2 | **Your Corner** (4x2) | "My five guys, standing in my corner." Parasocial anchor; drives favorites adoption. | ✅ favorites (Hive) + portraits (`assets/fighters/*.webp`) + booked bouts derivable from events | Easy-medium: one PNG render, 5 native tap targets. |
| 3 | **Face-Off** (4x4) | Wallpaper-grade poster of the next big fight. The Play-Store screenshot. | ✅ featured event + two portraits + Anton | Easy: static PNG, ~1 update/week. Ship first to prove the pipeline. |
| 4 | **Pick'Em Corner** (4x2, interactive) | Vote who wins *from the home screen*. Nobody in this category has interactive widgets. | ✅ next event + `PickCard` in prefs · ⚠️ community % is the deterministic demo hash (`communityPct`) — label it | Hard (the only hard one): Android `PendingIntent` → background Dart callback; iOS 17 AppIntents. |

Why these four: one **companion** (Living), one **identity** (Corner), one **poster**
(Face-Off), one **toy with agency** (Pick'Em). Four distinct jobs, zero overlap, and together
they cover 9 of the owner's 21 concepts (absorbed or shipped).

### v2 — second wave (after v1 telemetry)

| Widget | Notes / respec |
|---|---|
| **Belt Collection (#7)** | Data is strong (11 champions with portraits + gold `C` language). Respec: widgets cannot cycle "every few seconds" — cycle per timeline entry (iOS, free) / per 15-min tick (Android), plus a tap-to-advance button. |
| **Division Ladder (#9)** | Rankings + change deltas exist. Champion pinned in gold, top-5 with `▲▼` deltas. Caveat: deltas are almost all `0` in the current dataset — looks dead until data refreshes vary. |
| **Finish DNA (#12)** | `winsByKo/Sub/Dec` present for all 400 fighters. Great 2x2: three stacked bars (red/blue/gray), Anton percentage. Cheap. |
| **Tale of the Tape (#6)** | Respec: rotate height/reach/age per timeline entry, not seconds. iOS gets this ~free via pre-baked entries; Android via the 15-min tick. |
| **Walkout Card (#10)** | Ticket-styled collectible for the next event; pairs with the existing share-card feature (`/pickem-share/:id`). Marketing-cute, low info. |

### Cut list — one line each

| Concept | Reason |
|---|---|
| Fight Clock (#1) | Not cut — **absorbed** as the Living Widget's phase engine. |
| Octagon Countdown (#3) | Not cut — **absorbed** as the Living Widget's fight-week face. |
| Last Five Fights (#5) | Dataset has 8 past events; most fighters have ≤1 derivable result → widget renders mostly empty dots. Revisit when per-fighter history exists. |
| Fight Momentum (#8) | Same data gap as #5, plus it's a worse visualization of the same idea. |
| Hype Pulse (#11) | "Hype" is a hash (`communityPct`-style), and widgets can't animate a waveform. Simulated data + simulated motion = double dishonesty. |
| Octagon Radar (#13) | power/speed/cardio/IQ axes don't exist — would be invented mappings from striking stats; radar charts are illegible at 2x2 anyway. Keep radar in-app on the fighter profile. |
| Career Journey (#14) | Zero timeline data (no debut dates, no title-win dates). |
| Staredown (bonus) | Widgets cannot run continuous animation (RemoteViews/WidgetKit are static snapshots); faking a zoom with timeline frames burns the refresh budget on a gimmick. |
| Venue (bonus) | `venue` is an empty string for every event in the real dataset. Literally no data. |
| Fighter Focus (bonus) | As a standalone it's a shrunken profile screen — violates the POV. Its soul (artwork + name) lives in Face-Off and Living S0. |
| Ranking Shift (bonus) | **Absorbed** as Living Widget S6; standalone version is Division Ladder's job (v2). |
| KO Counter (bonus) | One number with no context; Finish DNA (v2) shows it better. |
| Style DNA (bonus) | Duplicate of Finish DNA. |
| Prediction (#15) | Not cut — shipped as **Pick'Em Corner**, v1 #4. |

---

## 3. v1 Per-Widget Specs

Conventions used below:

- **Sizes** are Android launcher cells; iOS mapping in parentheses.
- **PNG layer** = Flutter-prerendered via `home_widget`'s `renderFlutterWidget` (pixel-perfect
  Anton/aura/octagon). **Native layer** = RemoteViews / SwiftUI text drawn by the OS
  (crisp at any scale, can tick time without re-rendering).
- **Deep links** ride `home_widget`'s launch intent (`walkout://…` URI extra), mapped in Dart
  to the existing `AppRoutes` go_router paths. No manifest scheme changes needed for v1.
- "Featured event" = `EventRepository.getFeatured()` (soonest non-past event).
- "Corner fighter" = ids from `favoritesProvider` (Hive box `favorites`), resolved through
  `AppDataset.fighterById`.

---

### 3.1 The Living Widget  ⭐ centerpiece

**Pitch:** One widget, zero setup, that transforms with the fight calendar — fighter card in a
quiet week, face-off when a fight is booked, countdown in fight week, result the morning after.

**Sizes:** 4x2 primary (iOS medium), 2x2 compact (iOS small — same states, name + one line + ring only).

**Subject selection (zero-config):**
1. The corner fighter with the *soonest* upcoming bout (scan `mainCard`+`prelims` of non-past
   events for favorite ids).
2. If no favorite is booked → featured event (numbered UFC cards outrank Fight Nights when
   dates tie).
3. If favorites set is empty → featured event, with a "Build your corner" affordance in S0.

**Composition (4x2):**
- **PNG layer:** octagon-chamfered aura card, fighter/event art (`heroImage` /
  `assets/fighters/{id}.webp`), Anton name block, gold `C` badge, octagon countdown ring
  (drawn at render time at the % for the *next* re-render window — see cadence).
- **Native layer:** everything that ticks or must be correct to the minute — countdown
  digits (Android `Chronometer` with `countDown="true"`, API 24+; iOS
  `Text(timerInterval:)`), phase label, "LIVE" badge text.

**States, all of them:**

| State | Condition | Renders |
|---|---|---|
| EMPTY | no favorites AND no upcoming events in dataset | Walkout logotype + "Open Walkout to set up your corner" → `/onboarding/corner` |
| S0–S6 | see state machine, §4 | see §4 |
| STALE | widget data older than 48h (app not opened, work throttled) | last good face + "Open to refresh" caption in `textTertiary`; never show a wrong countdown — if `now > event.date` and no result data, render S4's "card in progress" face, not negative time |

**Refresh cadence & triggers:**
- Re-render PNGs on: app foreground, favorites change, Pick'Em change (Riverpod listeners).
- Phase flips at pre-computed boundary times: iOS timeline entries (free), Android exact
  alarms (`setExactAndAllowWhileIdle`) with a 15-min WorkManager tick as the fallback.
- Countdown digits tick natively — **zero refreshes spent on seconds/minutes**.

**Tap targets:** whole widget → state-dependent route: S0 `/fighter/:id` · S1–S3 `/event/:id`
· S3 pick chip → `/pickem-flow/:id` · S4 `/event/:id` · S5/S6 `/event/:id` (results).

**Data read:** `events.json` (dates, bouts, status, winnerId/method/finishRound),
`fighters.json` (name, record, isChampion, rankingPosition, imageUrl), `rankings.json`
(change deltas for S6), Hive favorites, `PickCard` (S3 lock reminder).

---

### 3.2 Your Corner

**Pitch:** Your five favorite fighters arranged like corners of the octagon, each with a status
ring — your corner, standing by on the home screen.

**Sizes:** 4x2 (iOS medium). 5 slots max; 1–4 favorites renders fewer, centered.

**Composition:**
- **PNG layer:** aura background with a faint octagon outline; up to 5 circular portraits
  (cropped from `assets/fighters/*.webp`) positioned at octagon vertex points; status ring
  stroked around each; 2-letter overline under each (`ISL`, `TOM` — first name trigram).
- **Native layer:** none (nothing ticks). 5 invisible native tap regions over the portraits.

```
 /------------------------------------------------------------\
 |        YOUR CORNER                                          |
 |    (o)         (o)         (o)         (o)         (o)     |
 |   ~red~       gold        gray        green       gray     |
 |   ISLAM        TOM        ALEX       KAYLA       SEAN      |
 |  FIGHT WK    BOOKED        —        WON SAT        —       |
 \------------------------------------------------------------/
```

**Status rings — derivable only (the brief's "training / media / inactive" states have no
data and are cut):**

| Ring | Color | Condition |
|---|---|---|
| FIGHT WEEK | brand red, thick | booked on a card ≤7 days out |
| BOOKED | gold | on an announced non-past card >7 days out |
| RESULT | success green (W) / danger red (L), fades after 72h | appears in a past event ≤72h old |
| IDLE | `border` gray, thin | none of the above |

**States:** empty (0 favorites) → octagon outline + "TAP TO BUILD YOUR CORNER" →
`/onboarding/corner`. Normal / fight-week / post-fight are per-slot ring states, not
whole-widget states. Stale: rings computed from dataset dates are safe to leave; portraits
never stale.

**Refresh cadence:** re-render on favorites change + app foreground; one scheduled re-render
per day at 00:05 local (ring states are day-granular). Cheapest widget in the suite.

**Tap targets:** each portrait → `/fighter/:id`; background → `/home`.

**Data read:** Hive favorites, `fighters.json`, `events.json` (booking scan).

---

### 3.3 Face-Off

**Pitch:** Two faces, edge to edge, `MAKHACHEV VS MACHADO GARRY` — a poster you keep on the
home screen for weeks. Minimal, wallpaper quality.

**Sizes:** 4x4 (iOS large). Optional 4x2 letterboxed variant later.

**Composition:**
- **PNG layer (everything):** full-bleed split composition — red-corner portrait left,
  blue-corner right, met by a hairline vertical divide with the brand-red radial aura rising
  from the center seam; Anton name stack bottom-left/bottom-right; small gold `TITLE FIGHT`
  overline when `isTitleFight`; event name + date in Inter `overline` at top.
- **Native layer:** none. This widget is deliberately 100% static art — it updates ~once a
  week when the featured event changes. Date text is baked into the PNG (day-granular, safe).

```
 /------------------------------------------------\
 |  UFC 330 · AUG 15                    T-MOBILE  |
 |                                                |
 |   ██████████            ▓▓▓▓▓▓▓▓▓▓             |
 |   ██ RED  ██     ⚡     ▓▓ BLUE ▓▓             |
 |   ██████████    aura    ▓▓▓▓▓▓▓▓▓▓             |
 |                                                |
 |  MAKHACHEV        VS       MACHADO GARRY       |
 |  26-1 · C                  16-0 · #3           |
 \------------------------------------------------/
```

**Subject:** main event of the featured event (`event.mainEvent`). If a corner fighter is
booked on any upcoming card, prefer *that* bout — the poster should be personal when it can be.

**States:** normal · no-upcoming-event (falls back to most recent past main event with a
`FINAL · W {method}` ribbon) · missing portrait (corner not in roster → initials block on
`brandContainer`, same as the app's avatar fallback) · stale (art can't be wrong at
day-granularity; date line always baked from data, never "in N days").

**Refresh cadence:** re-render when featured event changes or on app foreground; scheduled
daily check. ~1 real update/week.

**Tap targets:** whole widget → `/event/:id`.

**Data read:** `events.json` featured, `fighters.json` for both corners.

---

### 3.4 Pick'Em Corner (interactive)

**Pitch:** The main event's two corners with tappable pick buttons — make your pick from the
home screen, see the community split, jump into the full card.

**Sizes:** 4x2 (iOS medium; iOS 17+ for buttons, older iOS renders read-only + deep link).

**Composition:**
- **PNG layer:** aura card, two small portraits, Anton surnames, the split bar artwork.
- **Native layer:** two pick buttons (RemoteViews `setOnClickPendingIntent` /
  AppIntents `Button`), the "PICKS LOCK IN 3H" line if within 24h (native so it can restyle
  at the lock boundary), checkmark state overlay on the picked corner.

```
 /------------------------------------------------------------\
 |  UFC 330 MAIN EVENT                    PICKS LOCK IN 3H    |
 |   (o) MAKHACHEV          vs          MACHADO GARRY (o)     |
 |  [  PICK ✓  ]                          [   PICK   ]        |
 |  ██████████████████ 64% ─── 36% ▒▒▒▒▒▒▒     COMMUNITY·SIM  |
 \------------------------------------------------------------/
```

**Interaction flow (Android):** button → broadcast `PendingIntent` → `home_widget`
background Dart callback → `PickemController`-equivalent write (`FightPick(fighterId,
percent: 50)` for bout index 0 into the prefs blob `prefs.pickem_cards`) → re-render PNG →
`updateWidget`. Confidence tuning stays in-app; the widget records the pick at default
percent and the "REFINE YOUR CARD →" tap opens `/pickem-flow/:id`.

**States:** normal (no pick yet) · picked (gold check, picked corner ring) · locked
(`now ≥ event.date`: buttons removed, shows your pick vs community, "CARD LOCKED") ·
post-event (correct/wrong badge from `winnerId` + points, tap → `/pickem-results/:id`) ·
no upcoming event (falls back to last results summary) · stale (if lock time passed and no
re-render happened, native lock-line has already flipped the button container to GONE via
the pre-scheduled alarm — buttons can never fire after lock).

**Honesty flag:** the community split is `communityPct()` — a deterministic hash, not real
votes. The widget labels it `COMMUNITY · SIM` (small, `textTertiary`). Non-negotiable until
a backend exists.

**Refresh cadence:** re-render on pick change (from widget or app), lock-time alarm, event
result change, app foreground.

**Data read:** featured event main bout, both fighters, `prefs.pickem_cards` blob,
`communityPct(eventId, 0, fighterId)`.

---

## 4. Living Widget State Machine

### States & transitions

```
            fight announced              D-6 00:00               D-1 00:00
 [S0 CORNER] ───────────────▶ [S1 BOOKED] ─────────▶ [S2 FIGHT WEEK] ─────────▶ [S3 WEIGH-IN DAY]
      ▲                                                  (phases: media day,          │ D-0, first
      │                                                   workouts — labels           │ card segment
      │                                                   flip by day)                ▼
      │      72h after result                result data lands            [S4 FIGHT NIGHT]
 [S6 AFTERMATH] ◀──────────── [S5 RESULT] ◀───────────────────────────────────┘
      │                            ▲
      └────────────────────────────┴─── (if result never lands: S4 → S0 after 24h, no fake result)
```

Two trigger classes — never confuse them:

- **Calendar-time triggers** (knowable in advance → pre-schedulable): S1→S2→S3→S4 boundaries,
  phase label flips inside S2, S5→S6→S0 decay timers.
- **Data-change triggers** (only when the app/dataset updates): S0→S1 (fight announced),
  S4→S5 (`winnerId` populated / `status == past`), ranking deltas for S6.

**Data honesty:** the dataset carries a single `event.date` (main-card time) and no
weigh-in/prelim times. Phase times are **derived by convention** and labeled as schedule,
never as live fact:

| Phase | Derived time (from `event.date` = main card walk) |
|---|---|
| Media day | D-3, all-day label |
| Open workouts | D-2, all-day label |
| Weigh-ins | D-1 (official AM, ceremonial PM — label only, no times shown) |
| Early prelims | D-0, `date − 4h` |
| Prelims | D-0, `date − 2h` |
| Main card | `date` |

There is **no live-results feed** (no backend). S4 shows the scheduled running order — it
never pretends to know what round it is. S4→S5 fires only when refreshed data actually
contains `winnerId`.

### Faces (4x2 mockups)

**S0 — CORNER (quiet week).** Favorite fighter as standing presence.
```
 /------------------------------------------------------------\
 |  ((portrait))   ISLAM MAKHACHEV                      [ C ] |
 |  ((  aura  ))   LIGHTWEIGHT · 26-1                         |
 |                 NEXT: UFC 330 · AUG 15                     |
 \------------------------------------------------------------/
   PNG: all of it.  Native: none.  Tap → /fighter/islam-makhachev
```

**S1 — BOOKED (announced, >7 days).** Mini face-off, date-forward.
```
 /------------------------------------------------------------\
 |   (o)  MAKHACHEV                    MACHADO GARRY  (o)     |
 |        26-1 · C          VS               16-0 · #3        |
 |              UFC 330 · SAT AUG 15 · 37 DAYS                |
 \------------------------------------------------------------/
   PNG: portraits/names/aura.  Native: "37 DAYS" (flips daily, alarm at 00:00).
   Tap → /event/ufc-330
```

**S2 — FIGHT WEEK (D-6 … D-2).** Octagon ring starts filling red; phase label per day.
```
 /------------------------------------------------------------\
 |    __                                                      |
 |   /##\   MAKHACHEV vs MACHADO GARRY          3 DAYS        |
 |   \#_/   UFC 330                            14:22:05       |
 |  ring 55%  ── TODAY: OPEN WORKOUTS ──                      |
 \------------------------------------------------------------/
   PNG: ring at the % baked for this window, names, phase strip.
   Native: DAYS + HH:MM:SS chronometer.  Alarms: one per phase flip.
   Tap → /event/:id
```

**S3 — WEIGH-IN DAY (D-1).** The reminder face; Pick'Em pressure appears.
```
 /------------------------------------------------------------\
 |    __                                                      |
 |   /##\   WEIGH-IN DAY                     FIGHTS: 26:14:09 |
 |   \##/   MAKHACHEV vs MACHADO GARRY                        |
 |  ring 85%   [ YOUR PICKS: 3/13 · LOCK SOON → ]             |
 \------------------------------------------------------------/
   Native: countdown; picks chip is a native tap target → /pickem-flow/:id
```

**S4 — FIGHT NIGHT (D-0, from early-prelims time until result data).** Running order, no fake liveness.
```
 /------------------------------------------------------------\
 |  ● LIVE   UFC 330 · CARD IN PROGRESS                       |
 |  MAIN CARD                                                 |
 |  ▸ MAKHACHEV vs MACHADO GARRY        MAIN EVENT ~10PM      |
 |    PEREIRA vs ANKALAEV               CO-MAIN               |
 \------------------------------------------------------------/
   PNG: card order.  Native: LIVE dot row (pre-scheduled to appear at prelim time).
   Tap → /event/:id
```

**S5 — RESULT (first 24h after result data lands).** The morning-after payoff.
```
 /------------------------------------------------------------\
 |   ((portrait))    MAKHACHEV                    ┌───────┐   |
 |   (( gold    ))   WINS · SUBMISSION R3         │  W    │   |
 |   ((  aura   ))   UFC 330 MAIN EVENT           └───────┘   |
 |                   NOW 27-1  ·  STILL CHAMPION              |
 \------------------------------------------------------------/
   Green W block (danger-red L block on a loss — never hide losses).
   Tap → /event/:id
```

**S6 — AFTERMATH (24–72h).** New record + ranking movement, then decay to S0.
```
 /------------------------------------------------------------\
 |  THE DAY AFTER · LIGHTWEIGHT                               |
 |  C  MAKHACHEV   27-1        —                              |
 |  #3 MACHADO GARRY 16-1     ▼1                              |
 |  #2 GAETHJE                ▲1                              |
 \------------------------------------------------------------/
   From rankings.json change deltas. If deltas are all 0 (current dataset),
   render record change only and skip the ladder rows.
   Tap → /rankings
```

### Scheduling strategy per transition

**iOS (WidgetKit):** when data changes (app foreground / pick / favorite), build **one
timeline** containing an entry per known boundary out to ~2 weeks: S1 daily-midnight entries,
each S2 phase flip, S3 morning, S4 prelim/main-card times, plus decay entries. Entries within
a timeline are free; the ~40–70/day reload budget is only spent on data-change reloads
(`WidgetCenter.reloadTimelines`). Countdown digits use `Text(timerInterval:)` — live
per-second rendering with zero entries. This is the Flighty trick and it fits perfectly
because every boundary is derivable in advance.

**Android:** the Dart side pre-renders **all faces for the next 48h window** at data-change
time (S2 ring % per phase window, S3, S4 faces) and writes a schedule table
`[{atEpochMs, face, layoutVariant}]` to `home_widget` prefs. Native side:
- `AlarmManager.setExactAndAllowWhileIdle` at each boundary → `AppWidgetProvider.onReceive`
  swaps the referenced PNG + native text. Swapping a pre-rendered file is pure native — no
  Flutter engine spin-up at 4 AM.
- WorkManager periodic (15 min, battery-friendly constraints) as the safety net: checks the
  schedule table, corrects any missed alarm (Doze), and re-renders via a headless Dart
  callback only if the 48h face buffer has run dry.
- Countdown digits: `Chronometer` with `countDown="true"` inside the final 24h; day-granular
  text ("3 DAYS") swapped by the daily alarm outside it.
- `SCHEDULE_EXACT_ALARM` (API 31+): request `USE_EXACT_ALARM` is not justifiable here — use
  `setWindow` (±10 min) as the default and exact alarms only when the user has granted the
  special access; a ±10 min phase-label flip is acceptable, the native chronometer keeps the
  actual countdown exact regardless.

---

## 5. Technical Architecture

### Stack decision

- **Package:** `home_widget` (Dart data bridge + `renderFlutterWidget` PNG pipeline +
  background interactivity callbacks + launch-URI plumbing). Add `workmanager` for the
  Android periodic safety net.
- **Android rendering: RemoteViews XML, not Glance.** Reasons: (1) `Chronometer`
  `countDown` and `TextClock` are RemoteViews-native; Glance has no countdown primitive, so
  the signature live countdown would need minute-level recomposition — exactly the battery
  bill we're avoiding. (2) Our visual fidelity lives in the PNG layer; Glance's Compose-style
  layout buys nothing when the layout is `ImageView` + a few `TextView`s. (3) `home_widget`'s
  documented Android path is `AppWidgetProvider` + RemoteViews. Revisit Glance only if a
  future widget becomes layout-heavy and native.
- **iOS:** WidgetKit extension (SwiftUI), App Group `group.com.walkout.walkout` shared
  UserDefaults, `Text(timerInterval:)`, AppIntents buttons (iOS 17+).

### Where things live in this codebase

```
lib/features/home_widgets/
  application/
    widget_state_machine.dart      // pure Dart: LivingState f(now, events, favorites, picks)
    widget_schedule.dart           // boundary computation (phase table from event.date)
    widget_subject_resolver.dart   // corner-fighter-first, featured-event fallback
  data/
    widget_data_writer.dart        // serializes state → HomeWidget.saveWidgetData keys
    widget_render_service.dart     // renderFlutterWidget calls, file naming, 48h buffer
  faces/                           // ordinary Flutter widgets, reusing app primitives
    living_face_s0..s6.dart        //   (AuraCard, OctagonBorderShape, AppTypography,
    corner_face.dart               //    RankBadge) — rendered offscreen to PNG
    faceoff_face.dart
    pickem_face.dart
  home_widget_providers.dart       // Riverpod listeners: favorites/pickem/dataset → refresh

android/app/src/main/kotlin/com/walkout/walkout/widgets/
  LivingWidgetProvider.kt          // + CornerWidgetProvider, FaceoffWidgetProvider,
  PickemWidgetProvider.kt          //   PickemWidgetProvider (handles vote broadcasts)
  WidgetAlarmScheduler.kt          // exact/windowed alarms from the schedule table
android/app/src/main/res/layout/  widget_living_4x2.xml, widget_living_2x2.xml, …
android/app/src/main/res/xml/     appwidget provider info (sizes, previewImage)

ios/WalkoutWidgets/                // WidgetKit extension target (parity phase)
```

The state machine is deliberately pure Dart with `now` injected — unit-testable, and it
enables a **dev time-travel panel** (offset "now") which is the only way to demo/QA S4–S6
against a static bundled dataset. Build that panel in week 2; it's also how Play Store
screenshots get staged.

### Data flow

```
app foreground / favorites change / pick change / dataset update
        │  (Riverpod listeners in home_widget_providers.dart)
        ▼
resolve subject → compute state + 48h boundary schedule
        ▼
render faces → PNG files (path_provider app dir / iOS app-group container)
        ▼
HomeWidget.saveWidgetData: { state, schedule[], pngPaths{}, deepLink, chronometerBaseMs,
                             eventId, fighterIds[], lockEpochMs, pickedCorner }
        ▼
HomeWidget.updateWidget(android: 'LivingWidgetProvider', iOS: 'LivingWidget')
        +  WidgetAlarmScheduler re-arms boundaries (Android)
        +  WidgetCenter.reloadTimelines (iOS)
```

Pick'Em Corner reverse path: button `PendingIntent` → `HomeWidgetBackgroundIntent` → Dart
background callback → mutate `prefs.pickem_cards` blob (same format `PickemController`
reads) → re-render → update. Note: background isolate rendering requires fonts available —
see font vendoring below.

### Pre-render pipeline (Pixel-class densities)

Render at **3x logical** (covers Pixel 420dpi = 2.625x with headroom), `pixelRatio: 3.0`:

| Cell size | Logical target (dp) | PNG (px) | Used by |
|---|---|---|---|
| 2x2 | 158 × 158 | 480 × 480 | Living compact |
| 4x2 | 329 × 158 | 1000 × 480 | Living, Corner, Pick'Em |
| 4x4 | 329 × 345 | 1000 × 1040 | Face-Off |

- Launcher cells vary; layouts use `centerCrop` + PNG safe-margins (12dp transparent) so
  arbitrary launcher grids don't crop content.
- RemoteViews bitmap budget ≈ 1.5 × screen bytes (~15.5 MB on a Pixel 8); worst case here is
  Face-Off 4x4 ≈ 4.2 MB ARGB — fine, but never stack multiple full-bleed bitmaps in one layout.
- The 48h Living buffer is ≤ ~8 PNGs on disk; prune files older than the current schedule.
- **Fonts:** `google_fonts` fetches at runtime — unacceptable for background isolates and
  first-render correctness. Vendor `Anton-Regular.ttf` + Inter into `assets/fonts/`, declare
  in `pubspec.yaml`, and point `AppTypography` at the bundled family (keep `google_fonts` as
  the loader if preferred, but with bundled-asset config). Also copy Anton into
  `android/app/src/main/res/font/` for any native `TextView` that must match (phase labels);
  chronometer digits stay Inter/system for legibility.

### Build-order roadmap (v1)

| Week | Deliverable | Exit criteria |
|---|---|---|
| **1 — pipeline proof** | Add `home_widget` + `workmanager`; font vendoring; `widget_data_writer` + `widget_render_service`; **Face-Off 4x4 end-to-end on the Pixel** (provider, layout, deep link, daily refresh) | Face-Off on the launcher, tap opens `/event/:id`, survives reboot |
| **2 — Living engine** | `widget_state_machine` + `widget_schedule` (unit-tested, `now` injected); dev time-travel panel; faces S0–S2; RemoteViews 4x2 with chronometer; alarm scheduler | Time-travel a week and watch S0→S1→S2 flip on-device without opening the app |
| **3 — Living complete + Corner** | Faces S3–S6, empty/stale states, 2x2 variant; Your Corner widget (render + 5 tap regions + daily ring refresh) | Full S0→S6 cycle demo via time travel; Corner reflects favorite toggles within 1s of app change |
| **4 — Pick'Em Corner + hardening** | Interactive widget (broadcast → background Dart → pick write → re-render); lock-time behavior; QA matrix (launcher grids, Doze, reboot, locale, 0-favorite fresh install); staged Play Store screenshots | Pick from widget appears in `/pickem-flow`; no update path exceeds 1 refresh per boundary |
| *(post-v1)* | iOS WidgetKit parity: extension target, App Group, timelines for S0–S6, `Text(timerInterval:)`, AppIntents voting | — |

---

## 6. Risks & Open Questions

1. **Anton licensing — fine, but do it right.** Anton is SIL OFL: bundling TTFs in app assets
   and Android `res/font` is permitted; include the OFL license text in the repo/about
   screen. Do not rename the font family (OFL Reserved Font Name rules).
2. **Static dataset vs "living" promise.** `events.json` is bundled and frozen; S0→S1 and
   S4→S5 transitions only fire when the dataset updates. Mitigations: (a) the time-travel dev
   panel makes every state demoable; (b) ship the scraper refresh as an app-update cadence
   for now; (c) flag clearly in marketing that live-night results are not real-time. Decide
   pre-launch: is S4→S5 latency (next data refresh) acceptable messaging?
3. **Demo-data honesty.** Community split and anything "hype"-flavored is a deterministic
   hash. v1 labels: `COMMUNITY · SIM`. Never bake simulated numbers into a PNG without the
   label — screenshots outlive disclaimers.
4. **Refresh discipline.** All per-second/minute motion is native (chronometer /
   `timerInterval`). Budgeted refreshes: boundary flips (≤6/day worst case in fight week) +
   data-change renders. If a widget ever needs sub-15-min *data* freshness, the design is
   wrong — redesign, don't poll.
5. **Doze / missed alarms.** Windowed alarms can slip ±10 min; WorkManager tick self-heals.
   Acceptable for phase labels; the countdown itself never drifts (native). Test with
   `adb shell dumpsys deviceidle force-idle`.
6. **Image staleness & disk.** PNGs re-render on app open; stale-cap at 48h with the "Open to
   refresh" treatment. Prune superseded files each render pass.
7. **Launcher fragmentation.** Cell dp sizes differ per launcher/grid setting. PNG
   safe-margins + `centerCrop` + testing on Pixel launcher, Nova, Samsung One UI grid
   options. Provide `previewImage` per provider so the widget picker sells the suite.
8. **Interactive widget failure modes (Pick'Em).** Background Dart isolate needs bundled
   fonts (done via vendoring) and must complete render <10s; if the callback fails, the
   button must be idempotent (pick write is a prefs merge, safe to retry). Lock boundary is
   enforced by a pre-scheduled layout swap, not by trusting the callback.
9. **Play Store marketing.** The widget suite *is* the store listing: stage screenshots via
   the time-travel panel (fight-week S2 with ring at ~70% is the hero shot; Face-Off is
   screenshot #2). Budget a half-day in week 4 — this is the #1 selling point, treat the
   screenshots as a deliverable, not an afterthought.
10. **Open question — subject pinning.** Living Widget is zero-setup by design, but power
    users will ask to pin it to one fighter. Proposal: long-press configuration
    (`AppWidgetConfigure` / iOS widget config intent) in v2, default stays automatic. Decide
    after v1 feedback.
11. **Open question — multiple Living instances.** Users can place two Living Widgets. v1:
    all instances share one subject. v2 + pinning solves "one per fighter."
