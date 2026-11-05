# Kharcha — Design System: "Night Ledger"

> Dark luxury, neo-brutal. A private-bank ledger printed at night:
> near-black paper, hairline rules, oversized figures, one electric accent.

This document is the source of truth for every visual decision. Tokens live in
`lib/core/theme/tokens/` as `ThemeExtension`s and are read through
`context.colors`, `context.typeScale`, `context.space`, `context.radii`,
`context.elevation` and `context.motion` (see `theme_context.dart`).
**No widget may hard-code a color, font size, spacing value, radius or
duration.**

---

## 1. Principles

1. **Money is the hero.** Amounts are set in oversized Space Grotesk with
   tabular figures. The currency symbol and the fraction are smaller and
   dimmer than the integer part, so the eye lands on the number that matters.
2. **Rules, not shadows.** Structure comes from 1px hairlines and a tight
   grid. Soft blurred shadows are banned. When something must feel physically
   raised (primary actions, the quick-add key), it gets a *hard offset block*,
   a solid shape 4px behind it that the element sinks into when pressed.
3. **One accent, used sparingly.** The accent marks *the one thing you can do
   or the one thing going well* on a screen. If two accent elements compete,
   one of them is wrong.
4. **Editorial labels.** Section headers are small, uppercase, letter-spaced
   IBM Plex Mono, often numbered (`01 — TODAY`). They read like ledger column
   heads, not app chrome.
5. **Earned delight.** Celebration (confetti, haptic "thunk", counter roll) is
   reserved for real achievements: a goal hit, a level up, a streak milestone.
   Ordinary taps get a crisp press-scale and nothing more.
6. **State never lives in color alone.** Every color shift (budget ring going
   amber, red) is paired with a text label and, where relevant, an icon.

### Explicitly rejected
- Purple→blue gradients, glassmorphism, frosted blur panels.
- Default Material ink ripples (the theme uses `NoSplash`).
- Uniform card grids with identical radii and drop shadows.
- Emoji as icons. Icons are Phosphor (regular weight, bold when selected),
  centralized in `app_icons.dart` so the set can be swapped in one file.
- Spinners for content loading. Use skeletons with the scanline sweep.

---

## 2. Color

Two surfaces (dark is the flagship, light is "paper") × four accents. All
values are checked by `test/core/theme/contrast_test.dart`.

### 2.1 Neutrals

| Token            | Dark        | Light       | Use                                        |
|------------------|-------------|-------------|--------------------------------------------|
| `canvas`         | `#0A0A0B`   | `#F2F0EA`   | Scaffold background                        |
| `surface`        | `#131315`   | `#FAF9F5`   | Cards, sheets, bottom bar                  |
| `surfaceRaised`  | `#1B1B1E`   | `#FFFFFF`   | Inputs, keypad keys, nested tiles          |
| `line`           | `#26262A`   | `#DDDAD2`   | Decorative hairlines and dividers          |
| `lineStrong`     | `#6B6B73`   | `#86827A`   | Interactive borders (≥ 3:1 for WCAG 1.4.11)|
| `textPrimary`    | `#F4F3EE`   | `#0B0B0C`   | Primary text and numerals                  |
| `textSecondary`  | `#A8A7A0`   | `#55534D`   | Supporting text                            |
| `textTertiary`   | `#8C8B85`   | `#6A6862`   | Metadata, captions (still ≥ 4.5:1)         |

Dark neutrals are warm-shifted (slightly yellow whites, not blue) to feel like
paper under lamplight rather than a screen.

### 2.2 Accent palettes

Each accent defines a **fill** (large areas, always with `onAccent` text on
top) and a **strong** variant (used as text or strokes directly on a surface;
must pass 4.5:1). In dark mode they are the same; in light mode the strong
variant is a deep ink version of the hue.

| Accent      | Unlock   | Fill      | Strong (dark) | Strong (light) | onAccent  |
|-------------|----------|-----------|---------------|----------------|-----------|
| **Volt**    | default  | `#D7FF3A` | `#D7FF3A`     | `#4A6600`      | `#0A0A0B` |
| Glacier     | Level 5  | `#6FE3FF` | `#6FE3FF`     | `#00708A`      | `#0A0A0B` |
| Platinum    | Level 10 | `#EDEDED` | `#EDEDED`     | `#1A1A1A`      | `#0A0A0B` |
| Flamingo    | Level 20 | `#FF8FD1` | `#FF8FD1`     | `#B0246F`      | `#0A0A0B` |

**Primary action inversion.** In dark mode the primary button is an accent
fill with ink label. In light mode it flips to an *ink* button with an accent
label and an accent offset block behind it. Lime on paper is illegible; lime
on ink is electric.

### 2.3 Semantic: budget tones

Budget state is a four-step scale tied to the alert thresholds (defaults 50 / 80
/ 100 %, user-configurable).

| Tone      | Range      | Dark      | Light     | Label shown   |
|-----------|------------|-----------|-----------|---------------|
| `calm`    | < 50 %     | accent    | accent    | ON TRACK      |
| `watch`   | 50 – 79 %  | `#FFD37A` | `#7D5A00` | WATCH         |
| `warning` | 80 – 99 %  | `#FF9F2E` | `#A34700` | CLOSE TO LIMIT|
| `over`    | ≥ 100 %    | `#FF5A4E` | `#C2261B` | OVER BY ₹X    |

Accents were chosen to stay clear of this scale: no orange, amber or red
accents, so "warning" is never confused with "brand".

### 2.4 Measured contrast (text tokens)

Dark on `surfaceRaised` (the worst case): primary 15.5, secondary 7.1,
tertiary 5.0, danger 5.6. Light on `canvas`: primary 17.3, secondary 6.8,
tertiary 4.9, Volt-strong 5.8, Glacier-strong 5.0. Accent fills with ink
labels: 9.5 – 17.2.

---

## 3. Typography

| Family          | Role                                              |
|-----------------|---------------------------------------------------|
| Space Grotesk   | Display, headings, **every monetary amount**      |
| IBM Plex Sans   | Body copy, descriptions, insights                 |
| IBM Plex Mono   | Micro-labels, metadata, keypad digits, chips      |

Rules:
- **All amounts use `money*` styles**, which enable `tnum` (tabular figures)
  so columns of numbers align and animated counters don't jitter. Plex Sans
  has no `tnum` feature and must never render an amount.
- Labels are uppercase **in the source string**, not via a style transform,
  so screen readers get sensible text (use `SectionLabel`, which handles it).
- Display sizes use negative tracking; labels use positive tracking.
- Respect text scaling. Money hero styles shrink-to-fit (`FittedBox`) rather
  than clip when the user's text scale is large.

| Style          | Family        | Size / Height | Weight | Tracking |
|----------------|---------------|---------------|--------|----------|
| `moneyHero`    | Space Grotesk | 64 / 0.95     | 500    | −2.4     |
| `moneyLarge`   | Space Grotesk | 40 / 1.0      | 500    | −1.2     |
| `moneyMedium`  | Space Grotesk | 24 / 1.1      | 500    | −0.4     |
| `moneySmall`   | Space Grotesk | 16 / 1.2      | 500    | 0        |
| `display`      | Space Grotesk | 34 / 1.05     | 600    | −1.0     |
| `title`        | Space Grotesk | 22 / 1.15     | 600    | −0.4     |
| `titleSmall`   | Space Grotesk | 17 / 1.2      | 600    | −0.2     |
| `body`         | IBM Plex Sans | 15 / 1.45     | 400    | 0        |
| `bodyStrong`   | IBM Plex Sans | 15 / 1.45     | 600    | 0        |
| `bodySmall`    | IBM Plex Sans | 13 / 1.4      | 400    | 0        |
| `label`        | IBM Plex Mono | 11 / 1.3      | 500    | +1.2     |
| `labelLarge`   | IBM Plex Mono | 13 / 1.3      | 500    | +0.8     |

---

## 4. Space, radii, elevation

**Spacing** is a 4-based scale: `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 24 ·
xxl 32 · xxxl 48 · huge 64`. Screen gutter is `20`. Vertical rhythm between
sections is `xxl`; inside a section it is `md`/`lg`.

**Radii are role-based, deliberately unequal**:

| Role      | Value | Why                                                   |
|-----------|-------|-------------------------------------------------------|
| `card`    | 4     | Nearly square: ledger slips, not app tiles            |
| `control` | 8     | Inputs, keypad keys: slightly softer under the thumb  |
| `sheet`   | 20    | Only the top corners of bottom sheets                 |
| `chip`    | pill  | Filters and tags                                      |
| `action`  | 4     | Buttons match cards; the offset block gives them heft |

**Elevation** has three levels:

| Level      | Treatment                                                  |
|------------|------------------------------------------------------------|
| `flat`     | Surface color only                                         |
| `outlined` | Surface + 1px `line` border (default card)                 |
| `lifted`   | Surface + 1px `lineStrong` border + 4px hard offset block   |

Lifted elements **sink** into their block on press (translate 4px → 0px,
block shrinks to 0). That is the app's signature tactile gesture.

---

## 5. Motion

| Token       | Duration | Curve                       | Used for                           |
|-------------|----------|-----------------------------|------------------------------------|
| `tap`       | 90 ms    | `standard`                  | Press scale/sink                   |
| `fast`      | 150 ms   | `standard`                  | Fades, color shifts, toggles       |
| `medium`    | 240 ms   | `enter` / `exit`            | List items, banners, tab content   |
| `slow`      | 420 ms   | `enter`                     | Number counters, ring fills        |
| `reveal`    | 560 ms   | `enter`                     | Circular theme reveal              |
| `celebrate` | 1200 ms  | physics                     | Confetti, level-up                 |
| `stagger`   | 35 ms    | n/a                         | Delay between staggered list items |

Curves: `standard = Cubic(0.2, 0, 0, 1)`, `enter = Cubic(0.05, 0.7, 0.1, 1)`
(fast out, long settle), `exit = Cubic(0.3, 0, 0.8, 0.15)`. Bottom sheets use a
spring (`stiffness 520, damping 38`): slightly underdamped, no visible bounce.

Rules:
- Motion explains change: counters roll *from the old value*, rings fill
  *from their previous level*, list items enter staggered *only on first load*.
- **Reduced motion** (`MediaQuery.disableAnimations`): every duration resolves
  to zero via `context.motionDuration(...)`; the theme reveal becomes an
  instant swap; confetti is replaced by a static badge; press feedback uses
  opacity instead of scale.
- Nothing essential waits on an animation; taps are accepted during motion,
  except during the 560 ms theme reveal.

---

## 6. Signature components

| Component        | Signature detail                                              |
|------------------|---------------------------------------------------------------|
| `MoneyText`      | Split rendering: small raised symbol, huge integer, dim fraction |
| `AnimatedMoney`  | Tabular counter rolling from previous value                   |
| `BudgetRing`     | Square-capped arc, tick marks at thresholds, overflow lap     |
| `AppButton`      | Hard offset block, sinks on press, mono uppercase label       |
| `SectionLabel`   | `01 — LABEL` numbered ledger header with hairline rule        |
| `SkeletonGroup`  | Hard-edged scanline sweep, not a soft shimmer                 |
| Bottom bar       | Top-edge accent tick on the active tab, no pill indicator     |
| Quick-add key    | Square accent key with offset block, bottom-right             |
| Theme reveal     | Circular wipe from the toggle with a 1.5px accent edge        |

---

## 7. Accessibility checklist

- Text ≥ 4.5:1, interactive borders and graphics ≥ 3:1 (enforced by test).
- Touch targets ≥ 48×48 dp (`Pressable` enforces a minimum).
- Every icon-only control has a semantic label and tooltip.
- Focus: keyboard focus draws a 2px `accentStrong` outline.
- Text scaling up to 200% without clipping; hero numerals shrink-to-fit.
