# UF E-Wallet — Mobile App Design System & Screen Specification

> **Figma File:** [UF E-Wallet — Mobile App UI/UX](https://www.figma.com/design/JYDB0GY8WNGwoytEDczRRk/UF-E-Wallet-%E2%80%94-Mobile-App-UI-UX)
> **Version:** Dark Theme v1.0
> **Last Updated:** May 2026
> **Platforms:** iOS · Android
> **Languages:** English (LTR) · Arabic (RTL)

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Design Tokens](#2-design-tokens)
3. [Typography](#3-typography)
4. [Spacing & Layout Grid](#4-spacing--layout-grid)
5. [Component Library](#5-component-library)
6. [Screen Specifications](#6-screen-specifications)
   - [S1 — Splash Screen](#s1--splash-screen)
   - [S2 — Welcome & Phone Number](#s2--welcome--phone-number)
   - [S3 — OTP Verification](#s3--otp-verification)
   - [S4 — Biometric Setup](#s4--biometric-setup)
   - [S5 — Passcode Login](#s5--passcode-login)
   - [S6 — Home Screen](#s6--home-screen)
7. [Navigation Architecture](#7-navigation-architecture)
8. [Interaction & Animation Guidelines](#8-interaction--animation-guidelines)
9. [Bilingual (AR/EN) Implementation](#9-bilingual-aren-implementation)
10. [Dark Theme Implementation Notes](#10-dark-theme-implementation-notes)
11. [Asset Inventory](#11-asset-inventory)

---

## 1. Design Philosophy

### Brand Identity
Ultimate Finance (UF) is a Saudi Arabian e-wallet and financial services platform. The visual language is built around three core principles:

**Premium Dark Fintech**
The app uses a deep navy background with teal (#00E5C3) as the primary action color and purple (#6F4ADE) as an atmospheric accent. This combination feels trustworthy, modern, and premium — echoing the aesthetic of top-tier financial apps while staying culturally appropriate for the Saudi market.

**Breathing Space Over Density**
Every screen prioritises clarity. Sections are separated with generous vertical spacing. The home screen deliberately avoids cramming in too many competing elements — a balance card, a quick actions row, and a services grid give the user everything they need without visual noise.

**SF Pro Typography**
All text uses Apple's SF Pro font family (SF Pro Display for headings, SF Pro Text for body/labels). This gives the app a crisp, native-feeling character at every size. On Android, the fallback is Roboto with matching weights.

**Ambient Depth via Glow**
Rather than harsh shadows or flat cards, depth is created through subtle radial glows layered behind UI elements. Teal glow sits behind the balance area; purple glow in lower/secondary zones. These are always low-opacity (7–14%) blurred ellipses — never overpowering the content.

---

## 2. Design Tokens

### Color Palette

```
/* ── BRAND ─────────────────────────────────────── */
--color-teal:          #00E5C3   /* Primary CTA, active states, icons */
--color-teal-dark:     #00B39A   /* Pressed state, secondary teal */
--color-purple:        #6F4ADE   /* Accent glow, secondary highlights */
--color-purple-mid:    #4D30B0   /* Deeper purple variant */

/* ── DARK BACKGROUNDS ───────────────────────────── */
--color-bg-900:        #0A0B1E   /* Page background — deepest */
--color-bg-800:        #0D0F2B   /* Subtle variation */
--color-bg-surface:    #12142D   /* Card background, nav bar */
--color-bg-card:       #161835   /* Service cells, input fields */
--color-bg-elevated:   #1E214A   /* Modals, OTP boxes, numpad keys */

/* ── BORDERS ────────────────────────────────────── */
--color-border:        #323668   /* Default border, dividers */
--color-border-teal:   rgba(0, 229, 195, 0.20)   /* Balance card border */
--color-border-focus:  rgba(0, 229, 195, 0.50)   /* Active input border */

/* ── TEXT ───────────────────────────────────────── */
--color-text-primary:  #FFFFFF   /* Headings, key data */
--color-text-secondary:#B2B5D0   /* Body, labels, placeholders */
--color-text-dim:      #6B6F8E   /* Timestamps, fine print */
--color-text-teal:     #00E5C3   /* Links, active nav, CTA text */

/* ── STATUS ─────────────────────────────────────── */
--color-success:       #12D281   /* Success states */
--color-error:         #F44343   /* Error states, notification badge */
--color-warning:       #FFB800   /* Warnings */

/* ── OVERLAY ────────────────────────────────────── */
--color-overlay:       rgba(10, 11, 30, 0.80)   /* Modal backdrop */
```

### Elevation / Glow System

Depth is communicated through Gaussian-blurred ambient glows, not drop shadows.

| Level | Usage | Color | Opacity | Blur Radius |
|-------|-------|-------|---------|-------------|
| Glow-0 | Page background ambience | `#00E5C3` | 7% | 80px |
| Glow-1 | Balance card inner glow | `#00E5C3` | 13% | 70px |
| Glow-2 | Secondary atmospheric | `#6F4ADE` | 9% | 70px |
| Glow-3 | FAB drop shadow | `#00E5C3` | 45% | Drop shadow 14px |

---

## 3. Typography

**Font Family:** SF Pro (primary) / Roboto (Android fallback)

| Role | Family | Style | Size | Line Height | Usage |
|------|--------|-------|------|-------------|-------|
| Display | SF Pro Display | Bold | 40px | auto | Balance number |
| H1 | SF Pro Display | Bold | 28px | auto | Screen headlines |
| H2 | SF Pro Display | Bold | 24px | auto | Section titles |
| H3 | SF Pro | Semibold | 16–17px | auto | Section headers, nav labels |
| Body-L | SF Pro | Semibold | 15px | auto | Names, key labels |
| Body-M | SF Pro | Regular | 15px | auto | Input text, descriptions |
| Body-S | SF Pro | Medium | 13px | auto | Field labels, secondary UI |
| Caption | SF Pro | Regular | 12px | auto | Subtitles, timestamps |
| Micro | SF Pro | Semibold | 10px | auto | Nav labels, cell labels |
| Nano | SF Pro | Semibold | 9–10px | auto | Badges, chips |

**Text colour rules:**
- White `#FFFFFF` → headlines, balance figures, CTA button labels on teal
- Secondary `#B2B5D0` → descriptive text, input placeholders, nav labels (inactive)
- Teal `#00E5C3` → links, active nav, currency prefix, action hints
- Dim `#6B6F8E` → wallet ID, fine print

---

## 4. Spacing & Layout Grid

**Canvas:** 390 × 844 pt (iPhone 14 / 15 base frame)
**Safe areas:** Top 48pt status bar · Bottom 34pt home indicator
**Content padding:** 20pt horizontal (left and right)

### Vertical Rhythm

```
Status bar:       0–48pt
Top nav:         48–108pt   (60pt tall)
Balance card:   120–284pt   (164pt tall)
Quick actions:  300–396pt   (section label 13pt + 4pt gap + 56pt row + labels)
Services:       400–634pt   (section header + 2 rows × 92pt + 12pt gap)
Bottom nav:     762–844pt   (82pt tall)
```

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `space-4` | 4pt | Micro gaps |
| `space-8` | 8pt | Icon internal padding |
| `space-12` | 12pt | Button internal padding |
| `space-16` | 16pt | Card inner padding (sm) |
| `space-18` | 18pt | Card inner padding (default) |
| `space-20` | 20pt | Screen horizontal padding |
| `space-24` | 24pt | Section gaps |
| `space-32` | 32pt | Large section separation |

### Border Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `radius-8` | 8pt | Small chips |
| `radius-12` | 12pt | Buttons within cards |
| `radius-14` | 14pt | Input fields, quick action cells |
| `radius-16` | 16pt | Primary CTA buttons |
| `radius-20` | 20pt | Service cells |
| `radius-22` | 22pt | Service cells (alt) |
| `radius-24` | 24pt | Balance card |
| `radius-28` | 28pt | Bottom sheets |
| `radius-30` | 30pt | FAB (Transfer button) |
| `radius-44` | 44pt | Phone frame corners |

---

## 5. Component Library

### 5.1 Primary Button (CTA)

```
Background:   #00E5C3
Height:       56pt
Corner:       radius-16
Label:        SF Pro Semibold / 16pt / #0A0B1E
Padding-x:    centred
States:
  Default  → background #00E5C3
  Pressed  → background #00B39A, scale 0.98
  Disabled → background rgba(0,229,195,0.3), label rgba(10,11,30,0.4)
```

### 5.2 Secondary Button

```
Background:   #1E214A
Border:       1pt / #323668
Height:       56pt
Corner:       radius-16
Label:        SF Pro Semibold / 16pt / #B2B5D0
States:
  Default  → as above
  Pressed  → border-color #00E5C3 / opacity 0.5
```

### 5.3 Card Button (within Balance Card)

```
Primary variant:
  Background:   #00E5C3
  Height:       38pt
  Width:        calc((card_width - 36pt - 10pt) / 2)
  Corner:       radius-12
  Label:        SF Pro Semibold / 13pt / #0A0B1E

Ghost variant:
  Background:   #12142D
  Border:       1pt / rgba(0,229,195,0.30)
  Label:        SF Pro Semibold / 13pt / #00E5C3
```

### 5.4 Input Field

```
Background:   #1E214A
Border:       1pt / #323668
Height:       56pt
Corner:       radius-14
Placeholder:  SF Pro Regular / 15pt / #B2B5D0
Value text:   SF Pro Regular / 15pt / #FFFFFF
Padding-left: 16pt

States:
  Default  → border #323668
  Focused  → border rgba(0,229,195,0.5), glow 0 0 0 3pt rgba(0,229,195,0.10)
  Error    → border #F44343
```

### 5.5 OTP Box

```
Background:   #1E214A
Border:       1pt / #323668
Size:         46 × 56pt
Corner:       radius-12
Text:         SF Pro Bold / 24pt / #FFFFFF (active) | •  / #B2B5D0 (filled) | – (empty)

States:
  Active   → border 2pt / #00E5C3
  Filled   → border 1pt / #323668
  Error    → border 1pt / #F44343
```

### 5.6 Balance Card

```
Size:         350 × 164pt  (W - 40pt padding)
Background:   #12142D
Border:       1pt / rgba(0,229,195,0.18)
Corner:       radius-24
Overflow:     hidden (clips inner glow ellipse)

Internal layout (top to bottom):
  18pt from top → "AVAILABLE BALANCE" label  +  teal dot indicator
  27pt from top → Balance figure (SAR prefix + amount + .00)
  77pt from top → USD equivalent
  95pt line     → 1pt divider
  107pt from top → Top Up button + History button (equal width, 10pt gap)
  Corner chip   → "2% Cashback" badge (top-right, opacity 0.15 bg + teal text)
```

### 5.7 Quick Action Cell

```
Width:        (390 - 40 - 12) / 4 = ~84.5pt each, 4pt gaps
Height:       56pt
Background:   #161835
Border:       1pt / rgba(50,54,104,0.6)
Corner:       radius-14

Contents:
  Icon:   20 × 20pt SVG vector, y=7pt, x=centred
  Label:  SF Pro Medium / 10pt / #B2B5D0, centred, y=32pt
```

### 5.8 Service Cell

```
Width:        (390 - 40 - 24) / 3 = ~108.67pt each, 12pt gaps
Height:       92pt
Background:   #161835
Border:       1pt / rgba(50,54,104,0.6)
Corner:       radius-20
Top shine:    1pt white rectangle, opacity 5% (subtle gloss)

Contents:
  Glow dot:  36 × 36pt ellipse, y=9pt, x=centred, fill=accent_color / 12%
  Icon:      36 × 36pt SVG vector, y=9pt, x=centred, stroke=accent_color / 2pt
  Label:     SF Pro Semibold / 10pt / #B2B5D0, centred, y=69pt
```

### 5.9 Bottom Navigation Bar

```
Height:       82pt
Background:   #12142D + backdrop-blur 20pt
Border-top:   1pt / rgba(50,54,104,0.4)
Home indicator: 120pt × 4pt pill / white / opacity 20% / bottom 6pt

5 slots, equal width (390/5 = 78pt each):
  Slot 0: Home     — house vector, active=teal, fill=teal/20%
  Slot 1: Cards    — card vector, inactive=#B2B5D0
  Slot 2: Transfer — floating FAB (see below)
  Slot 3: Store    — cart vector, inactive=#B2B5D0
  Slot 4: Profile  — person vector, inactive=#B2B5D0

FAB (Transfer):
  Size:       52 × 52pt (floats 14pt above nav bar)
  Background: #00E5C3
  Corner:     radius-30 (circle)
  Shadow:     drop-shadow / #00E5C3 / 45% / 0 4pt 14pt
  Icon:       double-arrow transfer SVG / 24pt / #0A0B1E / stroke 2.2pt
```

### 5.10 Notification Badge

```
Size:         14 × 14pt ellipse
Background:   #F44343
Text:         SF Pro Semibold / 8pt / #FFFFFF
Position:     top-right of bell icon, offset -2pt / -2pt
```

### 5.11 Bell Icon Button (Notification)

```
Size:         36 × 36pt
Background:   #12142D
Border:       1pt / #323668
Corner:       radius-18 (circle)
Icon:         bell SVG / 22pt / #B2B5D0 / stroke 1.6pt
```

---

## 6. Screen Specifications

---

### S1 — Splash Screen

**Figma Node:** `16:3` (EN) · `18:3` (AR)
**Purpose:** Brand introduction during app cold start / loading

#### Layout

```
Canvas: 390 × 844 — #0A0B1E background
Clipping: radius-44

Ambient glows (z=0, behind everything):
  Glow A: 300×300pt ellipse, x=-80, y=200, fill=#00E5C3 / 12%, blur=80pt
  Glow B: 300×300pt ellipse, x=180, y=500, fill=#6F4ADE / 12%, blur=80pt

Logo mark:
  Node:       Image frame (UF logo PNG)
  Size:       120 × 120pt
  x:          (390 - 120) / 2 = 135pt  (centred)
  y:          290pt
  Corner:     radius-26pt
  Scale mode: FIT

Wordmark text:
  "Ultimate Finance"
  Font:  SF Pro Semibold / 18pt / #FFFFFF
  x:     120pt  (centred, ~150pt wide)
  y:     430pt

Tagline text:
  "محفظتك الرقمية" (AR) / tagline equiv (EN)
  Font:  SF Pro Regular / 14pt / #B2B5D0
  x:     140pt  (centred, ~110pt wide)
  y:     460pt

Loading indicator (3 dots):
  3 × 8pt circles, evenly spaced 16pt apart
  Center: x=195pt, y=760pt
  Active dot (centre): fill #00E5C3
  Inactive dots:       fill #B2B5D0 / 40%
```

#### States
- **Loading:** dots animate sequentially (pulse, 400ms each, loop)
- **Ready:** fade out, transition to S2 (first launch) or S5 (returning user)

---

### S2 — Welcome & Phone Number

**Figma Node:** `16:21` (EN) · `18:13` (AR)
**Purpose:** First-time user onboarding — collect phone number and national ID

#### Layout

```
Status bar:  y=0,  h=44pt,  bg=#0A0B1E
Time text:   "9:41", x=20, y=14, SF Pro Semibold 15pt white

Ambient glows:
  Glow A: 300×300pt, x=-60, y=100, teal / 12%, blur 80pt
  Glow B: 300×300pt, x=200, y=600, purple / 12%, blur 80pt

Logo (small, centred):
  Size: 52 × 52pt
  x: (390 - 52) / 2 = 169pt
  y: 72pt
  Corner: radius-11.44pt

Headline:
  "Welcome to UF"
  Font:  SF Pro Bold / 28pt / #FFFFFF
  x:     32pt
  y:     152pt
  Width: 326pt

Subheadline:
  "Your trusted financial companion\nin Saudi Arabia"
  Font:  SF Pro Regular / 15pt / #B2B5D0
  x:     32pt
  y:     196pt
  Width: 326pt

--- MOBILE NUMBER FIELD ---

Field label: "Mobile Number"
  Font: SF Pro Semibold / 13pt / #B2B5D0
  x: 32pt, y: 268pt

Input frame:
  x: 32,  y: 290,  w: 326,  h: 56
  bg: #1E214A,  border: 1pt rgba(0,229,195,0.5),  radius-14

  Country code pill (inside input):
    x: 7,  y: 7,  w: 72,  h: 40,  bg: #1A1D46, radius-10
    Text: "🇸🇦 +966" — SF Pro Regular 12pt white, x=6, y=11

  Placeholder:
    "05X XXX XXXX"
    x: 91pt (after country code + 12pt gap)
    y: 18pt (within input)
    SF Pro Regular 15pt #B2B5D0

--- NATIONAL ID FIELD ---

Field label: "National ID / Iqama"
  Font: SF Pro Semibold / 13pt / #B2B5D0
  x: 32pt, y: 366pt

Input frame:
  x: 32,  y: 388,  w: 326,  h: 56
  bg: #1E214A,  border: 1pt #323668,  radius-14

  Placeholder: "Enter your 10-digit ID"
    x: 15pt, y: 17pt (within frame)
    SF Pro Regular 15pt #B2B5D0

--- T&C CHECKBOX ROW ---

Checkbox:
  20 × 20pt,  bg: #1E214A,  border: 1pt #323668,  radius-6
  x: 32,  y: 441pt
  Checked state: fill #00E5C3, checkmark white 1.5pt

Text: "I agree to the Terms & Conditions and Privacy Policy"
  x: 60,  y: 441pt,  width: 266pt
  SF Pro Regular 13pt #B2B5D0
  "Terms & Conditions" and "Privacy Policy" → underline, color #00E5C3

--- CTA BUTTON ---

"Continue →"
  x: 32,  y: 526,  w: 326,  h: 56
  bg: #00E5C3, radius-16
  Font: SF Pro Semibold / 16pt / #0A0B1E, centred

--- SIGN IN LINK ---

"Already have an account? Sign In"
  x: 82,  y: 606,  width: 226pt
  SF Pro Regular 14pt #B2B5D0
  "Sign In" → teal #00E5C3
```

#### Validation Rules
- Phone: Saudi format `05XXXXXXXX` (10 digits), required
- National ID / Iqama: exactly 10 digits, required
- T&C checkbox: must be checked before Continue is enabled
- Continue button: disabled state when fields incomplete (opacity 0.5)

---

### S3 — OTP Verification

**Figma Node:** `16:42` (EN) · `18:34` (AR)
**Purpose:** Verify phone ownership via 6-digit SMS code

#### Layout

```
Status bar: y=0, h=44pt, bg=#0A0B1E
Back arrow: "←" / SF Pro Regular 20pt / #00E5C3 / x=32, y=80

Logo (centred):
  Size: 52×52pt, x=169, y=118, corner radius-11.44

Headline: "Verify Your Number"
  SF Pro Bold / 24pt / #FFFFFF
  x: 32,  y: 192,  width: 326pt

Sub: "We sent a 6-digit code to\n+966 5XX XXX XXXX"
  SF Pro Regular / 15pt / #B2B5D0
  x: 32,  y: 232,  width: 326pt

--- OTP BOXES (6 boxes) ---

Box dimensions: 46 × 56pt each
Corner: radius-12
Horizontal positions: x = 32 + (i × 54)  →  32, 86, 140, 194, 248, 302
y: 300pt

Box states:
  Active (current):
    bg: #1E214A,  border: 2pt #00E5C3
    text: SF Pro Bold / 24pt / #FFFFFF
  Filled:
    bg: #1E214A,  border: 1pt #323668
    text: "•" / SF Pro Bold / 28pt / #B2B5D0  (centred)
  Empty:
    bg: #1E214A,  border: 1pt #323668
    text: "–"   / SF Pro Bold / 20pt / #B2B5D0  (centred)
  Error:
    bg: #1E214A,  border: 1pt #F44343
    Shake animation: 3× 4pt horizontal, 80ms

Resend link:
  "Resend code in 00:45"
  x: 115, y: 380, width: 160pt, centred
  SF Pro Regular / 13pt / #B2B5D0
  Countdown: when 0 → "Resend code" in #00E5C3 (tappable)

--- CTA ---

"Verify & Continue"
  x: 32,  y: 450,  w: 326,  h: 56
  bg: #00E5C3, radius-16
  SF Pro Semibold / 16pt / #0A0B1E, centred
```

#### Logic
- Auto-advance focus to next box on digit entry
- Auto-submit when all 6 boxes filled
- Shake + error border on wrong code
- Countdown timer: 45s, then resend available

---

### S4 — Biometric Setup

**Figma Node:** `16:66` (EN) · `18:57` (AR)
**Purpose:** Offer Face ID / fingerprint after first successful verification

#### Layout

```
Status bar: y=0, h=44pt
Logo (centred): 52×52pt, x=169, y=72

Fingerprint / Face ID illustration:
  Outer circle:  120×120pt, x=135, y=220
    fill: #1E214A,  border: 2pt rgba(0,229,195,0.6)
  Ring 1 (inner): 80×80pt, concentric
    fill: none, border: 1.5pt rgba(0,229,195,0.4)
  Ring 2:         60×60pt, concentric
    fill: none, border: 1.5pt rgba(0,229,195,0.35)
  Ring 3 (core):  40×40pt, concentric
    fill: none, border: 1.5pt rgba(0,229,195,0.3)
  Animation: rings pulse outward on loop (scale 1→1.05, 800ms, staggered)

Headline: "Enable Biometric\nLogin"
  SF Pro Bold / 26pt / #FFFFFF
  x: 55,  y: 376,  width: 280pt

Body: "Use Face ID or fingerprint to sign\nin quickly and securely"
  SF Pro Regular / 15pt / #B2B5D0
  x: 40,  y: 450,  width: 310pt

Primary CTA: "Enable Face ID / Fingerprint"
  x: 32,  y: 556,  w: 326,  h: 56
  bg: #00E5C3, radius-16
  SF Pro Semibold / 16pt / #0A0B1E, centred

Secondary CTA: "Use Passcode Instead"
  x: 32,  y: 628,  w: 326,  h: 56
  bg: #1E214A, radius-16
  SF Pro Semibold / 16pt / #B2B5D0, centred
```

#### Logic
- "Enable Face ID" → triggers native biometric enrollment API
- "Use Passcode Instead" → navigates to S5
- If biometric enrollment succeeds → save preference, go to Home
- If biometric not available on device → hide primary CTA, show only passcode option

---

### S5 — Passcode Login

**Figma Node:** `16:83` (EN) · `18:74` (AR)
**Purpose:** Recurring login via 6-digit passcode (also used when biometrics fail)

#### Layout

```
Status bar: y=0, h=44pt
Logo (centred): 52×52pt, x=169, y=72

Headline: "Enter Passcode"
  SF Pro Bold / 24pt / #FFFFFF
  x: 95,  y: 148,  width: 200pt, centred

Subtitle: "Welcome back, Ahmed"
  SF Pro Regular / 14pt / #B2B5D0
  x: 110,  y: 184,  width: 170pt, centred

--- PASSCODE INDICATOR DOTS (6 dots) ---

Dot size: 18×18pt each
y: 254pt
x positions: (390/2) - 72 + (i × 26)  →  spaced 26pt apart (centred)

States:
  Filled:   fill #00E5C3
  Empty:    fill #1E214A, border 1pt #323668

--- NUMPAD (3×4 grid) ---

Key size: 88×88pt each (circular, radius-44)
Background: #1E214A,  border: 1pt #323668
Font: SF Pro Bold / 24pt / #FFFFFF
Gap between keys: ~22pt horizontal (centred to 390pt canvas)
  col_x = 51 + col × 110

Row y positions:
  Row 0 (1-2-3): y=320
  Row 1 (4-5-6): y=420
  Row 2 (7-8-9): y=520
  Row 3 ( -0-⌫): y=620

Empty cell (row 3, col 0): transparent, no border

States:
  Default:  bg #1E214A
  Pressed:  bg #323668, scale 0.95, 80ms spring

"Forgot Passcode?" link:
  x: 130,  y: 760,  width: 130pt, centred
  SF Pro Regular / 14pt / #00E5C3
```

#### Logic
- 6-digit PIN
- Biometric icon in bottom-left of numpad (on devices with biometrics enabled) → triggers FaceID/Touch
- 5 wrong attempts → 30s cooldown
- "Forgot Passcode?" → re-verification flow (back to S2)

---

### S6 — Home Screen

**Figma Node:** `43:3` (EN) · `29:3` (AR)
**Purpose:** Main dashboard — balance, quick actions, services

#### Complete Layout Specification

```
Canvas: 390 × 844pt, bg=#0A0B1E, radius-44, clips content

--- AMBIENT BACKGROUND GLOWS ---
Glow A: 320×320pt ellipse, x=-80, y=-60
  fill: #00E5C3, opacity: 7%, blur: 80pt  (top-left teal ambient)
Glow B: 280×280pt ellipse, x=220, y=560
  fill: #6F4ADE, opacity: 9%, blur: 80pt  (bottom-right purple ambient)

--- ① STATUS BAR (y=0, h=48pt) ---
bg: #0A0B1E (solid)
Time: "9:41" — SF Pro Semibold 15pt white, x=20, y=17
Signal: 3× 6pt circles, x=316/326/336, y=21, opacity 55/70/85%
Battery frame: 25×12pt, x=350, y=18, border 1pt white/55%, radius-3
Battery fill:  18×8pt, x=352, y=20, fill white, radius-2
Battery tip:   3×6pt,  x=376, y=21, border 1pt white/55%, radius-2

--- ② TOP NAVIGATION (y=48, h=60pt) ---
bg: #0A0B1E

UF Logo:
  Size: 34×34pt, x=20, y=59
  Image fill: logo PNG (imageHash: bcd84e7f71b8e00eca17d5556160e73b80b68960)
  Corner: radius-7.5pt, scaleMode: FIT

User name: "Ahmed Al-Rashid"
  SF Pro Semibold 15pt #FFFFFF, x=62, y=58

Greeting: "Good morning ☀️"
  SF Pro Regular 12pt #B2B5D0, x=62, y=77

Notification bell (right):
  Frame 36×36pt, x=334, y=58
  bg: #12142D, border 1pt #323668, radius-18
  Bell icon SVG 22pt: stroke #B2B5D0, strokeW 1.6pt, centred

Notification badge:
  Ellipse 14×14pt, x=357, y=56
  fill: #F44343
  "3" — SF Pro Semibold 8pt white, x=360, y=59

--- ③ BALANCE CARD (y=120, h=164pt) ---
Frame: 350×164pt, x=20, y=120 (or 326×164, x=32 — centred)
bg: #12142D, border: 1pt rgba(0,229,195,0.18), radius-24, clips content

Inner teal glow:
  200×200pt ellipse, x=159, y=-51
  fill: #00E5C3, opacity 13%, blur 70pt

"AVAILABLE BALANCE" label:
  x=17, y=15 (within card)
  SF Pro Medium 10pt #B2B5D0

Active indicator dot:
  6×6pt ellipse, x=255, y=19 (or at end of label)
  fill: #00E5C3

Currency prefix "SAR":
  x=17, y=39 (within card)
  SF Pro Medium 14pt #00E5C3

Balance figure "12,450":
  x=51, y=27 (within card)
  SF Pro Bold 40pt #FFFFFF

Decimal ".00":
  x=185, y=46 (within card)
  SF Pro Medium 20pt #B2B5D0

USD equivalent "≈ USD 3,317":
  x=17, y=77 (within card)
  SF Pro Regular 11pt #B2B5D0

Separator line:
  286×1pt, x=17, y=95, fill #323668

Top Up button:
  w=(card_width-34-10)/2 ≈ 152pt, h=38pt
  x=17, y=107 (within card)
  bg: #00E5C3, radius-12
  Arrow-up icon SVG 20pt: stroke #0A0B1E, sw 2.2pt, x=9, y=9
  "Top Up" — SF Pro Semibold 13pt #0A0B1E, x=35, y=11

History button:
  w≈152pt, h=38pt
  x=179, y=107 (within card)
  bg: #12142D, border 1pt rgba(0,229,195,0.30), radius-12
  Clock icon SVG 20pt: stroke #00E5C3, sw 1.8pt, x=8, y=9
  "History" — SF Pro Semibold 13pt #00E5C3, x=35, y=10

Cashback chip (top-right corner of card):
  68×22pt frame, x=card_width-18-68, y=15
  bg: #00E5C3, opacity 15%, radius-11
  "2% Cashback" — SF Pro Semibold 9pt #00E5C3, centred, y=21

--- ④ QUICK ACTIONS (y≈300) ---
Section label: "Quick Actions"
  x=20, y=300
  SF Pro Semibold 13pt #B2B5D0

4 action cells (y=320, h=56pt each):
  Total width: 390 - 40 = 350pt
  Cell width: (350 - 3×4) / 4 = 84.5pt
  Gap: 4pt
  x positions: 20, 108.5, 197, 285.5

  Cell style:
    bg: #161835, border 1pt rgba(50,54,104,0.6), radius-14

  Cell contents (icon SVG 20×20pt at y=7, centred-x; label 10pt at y=32, centred):
    Send     → double right arrow, stroke #00E5C3
    Receive  → double left arrow, stroke #9973FF (purple-light)
    Scan     → square-scan frame, stroke #33D18C (green)
    Pay      → house/wallet, stroke #FFB800 (amber)

--- ⑤ SERVICES SECTION (y≈396) ---
Section header row:
  "Services" — SF Pro Semibold 16pt #FFFFFF, x=20, y=396
  "See all →" — SF Pro Medium 12pt #00E5C3, x=312, y=398, w=58pt

3×2 grid of service cells (y=424, 528):
  Grid start x: 20pt
  Cell size: ~108.67 × 92pt
  Column gap: 12pt
  Row gap: 12pt
  Columns: 3,  Rows: 2

  Service cells (label / icon stroke color):
    [0,0] UF Transfer  — double-arrow transfer SVG     / stroke #00E5C3
    [0,1] SADAD Bills  — document/receipt SVG          / stroke #9973FF
    [0,2] Qattah       — credit card SVG               / stroke #33D18C
    [1,0] Traffic Fine — traffic light SVG             / stroke #FFB800
    [1,1] Request      — person + plus-circle SVG      / stroke #F44343
    [1,2] More         — 4-square grid SVG             / stroke #B2B5D0

  Cell structure (per cell):
    bg: #161835, border 1pt rgba(50,54,104,0.6), radius-20, clips content
    Top shine: 1pt white rect at y=0, opacity 5%
    Glow dot: 36×36pt ellipse, x=(cell_w-36)/2, y=9, fill=stroke_color/12%
    Icon: 36×36pt SVG, same x as glow dot, y=9, stroke=stroke_color, sw=2pt
    Label: SF Pro Semibold 10pt #B2B5D0, centred, y=69pt (bottom of cell)

--- ⑥ BOTTOM NAVIGATION BAR (y=762, h=82pt) ---
bg: #12142D + backdrop-blur 20pt
border-top: 1pt rgba(50,54,104,0.4)

5 slots, width=78pt each:
  Slot 0 Home    x=26:   house icon (active), teal + teal/20% fill
  Slot 1 Cards   x=104:  card icon (inactive), #B2B5D0
  Slot 2 Transfer FAB:   (see below)
  Slot 3 Store   x=260:  cart icon (inactive), #B2B5D0
  Slot 4 Profile x=338:  person icon (inactive), #B2B5D0

All nav icons: 24×24pt SVG, stroke weight 1.6–1.8pt, y=11pt within navBar
All nav labels: SF Pro Semibold (active) / Regular (inactive), 10pt, centred, y=39pt

FAB:
  52×52pt, x=168, y=-14 (floats above nav bar)
  bg: #00E5C3, radius-30
  Drop shadow: 0 4 14 rgba(0,229,195,0.45)
  Transfer icon SVG 24pt: stroke #0A0B1E, sw 2.2pt, centred
  "Transfer" label: 9pt teal, centred below FAB at y=41pt

Home indicator pill:
  120×4pt, x=(390-120)/2=135, y=76pt (within navBar)
  fill: #FFFFFF, opacity 20%, radius-2
```

---

## 7. Navigation Architecture

```
App Launch
    │
    ├─── First Launch ──────────────────────────────────────────────┐
    │         │                                                      │
    │      Splash (S1)                                              │
    │         │ 2.5s or asset load                                  │
    │         ▼                                                      │
    │      Welcome (S2) ──── phone + ID ────► OTP (S3)             │
    │                                              │                 │
    │                                         verified              │
    │                                              │                 │
    │                                         Biometric (S4)        │
    │                                         ┌────┴────┐           │
    │                                    Enable       Passcode      │
    │                                         └────┬────┘           │
    │                                              ▼                 │
    └─── Returning User ───────────────────► Home (S6) ◄────────────┘
              │
           Splash (S1)
              │
              ▼
           Biometric auto-prompt → success → Home (S6)
           Biometric fail / manual → Passcode (S5) → Home (S6)

Bottom Tab Navigation (within Home):
  Home    → Home (S6)  [current]
  Cards   → Cards screen  [next]
  Transfer → Transfer modal/screen  [next]
  Store   → Store screen  [next]
  Profile → Profile screen  [next]
```

---

## 8. Interaction & Animation Guidelines

### Transitions
| From → To | Type | Duration | Easing |
|-----------|------|----------|--------|
| Splash → Welcome | Crossfade + slide up | 400ms | ease-out |
| Any → Next (auth flow) | Slide left | 300ms | spring (0.8, 80) |
| Any → Back | Slide right | 280ms | spring (0.8, 80) |
| Welcome → Home | Scale fade | 450ms | ease-in-out |
| Tab switch | Crossfade | 200ms | linear |

### Micro-interactions
| Element | Trigger | Animation |
|---------|---------|-----------|
| Primary button | Tap | Scale 0.98 → 1.0, 80ms, bg darken 10% |
| Numpad key | Tap | Scale 0.95 → 1.0, 80ms, bg lighten |
| OTP box fill | Digit entry | Scale 1.08 → 1.0, 120ms spring |
| OTP wrong code | Error | Shake ±4pt × 3, 80ms each |
| Biometric rings | Idle | Pulse outward, staggered 200ms, loop |
| Service cell | Tap | Scale 0.96 → 1.0, 100ms |
| FAB | Tap | Scale 0.92 → 1.0, 150ms spring |
| Balance card reveal | Screen entry | Slide up 20pt + fade, 350ms |
| Loading dots | Splash | Sequential pulse, 400ms/dot, loop |

### Haptics (iOS)
| Event | Haptic |
|-------|--------|
| OTP box fill | Light impact |
| OTP complete | Medium impact |
| OTP wrong | Error notification |
| Biometric success | Success notification |
| CTA button tap | Light impact |
| FAB tap | Medium impact |

---

## 9. Bilingual (AR/EN) Implementation

### RTL Layout Rules

All Arabic screens mirror horizontally:

| Element | EN (LTR) | AR (RTL) |
|---------|----------|----------|
| Logo position in nav | Far left | Far right |
| User name position | Left of bell | Right of bell |
| Notification bell | Far right | Far left |
| Balance text alignment | Left-aligned | Right-aligned |
| Button order (Top Up / History) | Top Up left | Top Up right |
| "See all" link | Right-aligned | Left-aligned |
| Offer banner text | Left-aligned | Right-aligned |
| Back arrow | ← left | → right |
| Numpad layout | Standard (identical — numbers are universal) |
| Bottom nav order | Home ← left · Profile → right | Profile ← left · Home → right |

### Arabic Typography Notes
- Arabic content uses the same SF Pro font (it includes Arabic glyphs)
- `dir="rtl"` attribute on text containers
- `textAlignHorizontal: RIGHT` in Figma for all AR text nodes
- Arabic numerals used in UI labels; Western numerals used for financial figures (SAR amounts, dates)

### String Reference

| Key | English | Arabic |
|-----|---------|--------|
| `nav.home` | Home | الرئيسية |
| `nav.cards` | Cards | البطاقات |
| `nav.transfer` | Transfer | تحويل |
| `nav.store` | Store | المتجر |
| `nav.profile` | Profile | الملف |
| `splash.tagline` | Your Digital Wallet | محفظتك الرقمية |
| `welcome.headline` | Welcome to UF | اهلا بك في UF |
| `welcome.sub` | Your trusted financial companion in Saudi Arabia | رفيقك المالي الموثوق في المملكة |
| `field.mobile` | Mobile Number | رقم الجوال |
| `field.mobile.placeholder` | 05X XXX XXXX | 05X XXX XXXX |
| `field.id` | National ID / Iqama | رقم الهوية / الاقامة |
| `field.id.placeholder` | Enter your 10-digit ID | ادخل رقمك المكون من 10 ارقام |
| `terms` | I agree to the Terms & Conditions | اوافق على الشروط والاحكام |
| `btn.continue` | Continue → | متابعة ← |
| `btn.signin` | Already have an account? Sign In | لديك حساب؟ تسجيل الدخول |
| `otp.headline` | Verify Your Number | تاكيد رقم الجوال |
| `otp.sub` | We sent a 6-digit code to | ارسلنا رمزا مكونا من 6 ارقام الى |
| `otp.resend` | Resend code in {n} | اعادة ارسال الرمز خلال {n} |
| `otp.btn` | Verify & Continue | تحقق ومتابعة |
| `biometric.headline` | Enable Biometric Login | تفعيل البصمة |
| `biometric.sub` | Use Face ID or fingerprint to sign in quickly | استخدم بصمة وجهك او اصبعك |
| `biometric.btn.enable` | Enable Face ID / Fingerprint | تفعيل البصمة / Face ID |
| `biometric.btn.passcode` | Use Passcode Instead | استخدام الرمز السري |
| `passcode.headline` | Enter Passcode | ادخل الرمز السري |
| `passcode.sub` | Welcome back, {name} | اهلا بعودتك، {name} |
| `passcode.forgot` | Forgot Passcode? | نسيت الرمز السري؟ |
| `home.balance.label` | AVAILABLE BALANCE | الرصيد المتاح |
| `home.btn.topup` | Top Up | تعبئة |
| `home.btn.history` | History | السجل |
| `home.quick` | Quick Actions | إجراءات سريعة |
| `home.qa.send` | Send | إرسال |
| `home.qa.receive` | Receive | استلام |
| `home.qa.scan` | Scan | مسح |
| `home.qa.pay` | Pay | دفع |
| `home.services` | Services | الخدمات |
| `home.seeall` | See all → | عرض الكل |
| `svc.transfer` | UF Transfer | تحويل UF |
| `svc.sadad` | SADAD Bills | فواتير سداد |
| `svc.qattah` | Qattah | قطة |
| `svc.traffic` | Traffic Fine | مخالفات |
| `svc.request` | Request | طلب مبلغ |
| `svc.more` | More | المزيد |
| `home.greeting.morning` | Good morning ☀️ | صباح الخير ☀️ |
| `home.offer` | Exclusive Offer | عرض حصري |
| `home.offer.text` | 2% cashback on all transfers this month | 2% كاش باك على التحويلات هذا الشهر |

---

## 10. Dark Theme Implementation Notes

### Why Dark-First
The dark theme was designed first to match the company's existing web brand (deep navy + teal). The dark theme is production-ready. Light theme will be added in a future sprint and will share all the same token names with overridden values.

### Background Hierarchy
```
Level 4 (deepest) — Page:     #0A0B1E
Level 3            — Surface: #12142D  (nav bar, cards)
Level 2            — Card:    #161835  (service cells, action cells)
Level 1 (shallowest) — Input: #1E214A  (fields, OTP boxes, numpad keys)
```

Always step through exactly one level when nesting containers. A surface on a page ✓. A card on a surface ✓. Do not skip levels or use the same level for nested containers.

### Glassmorphism Rule
The bottom navigation bar uses `backdrop-filter: blur(20px)` (CSS) / `BACKGROUND_BLUR` (Figma) to create a frosted glass effect. This requires the nav bar to be semi-transparent rather than fully opaque. In implementation, ensure the nav background has `opacity: 0.92` or is defined as `rgba(18, 20, 45, 0.92)` rather than `#12142D` to let the blur effect show.

### Glow Management
Ambient glows must always be **behind** content in the z-order. In React Native, use `position: 'absolute'` with `zIndex: 0`; content should be `zIndex: 1`. In Figma, glows are the first children of each frame. Never animate glows on low-end devices — gate behind `ReduceMotion`.

### Status Bar
Always use `light-content` style (white text/icons) on both iOS and Android for the dark theme. On Android, set `statusBarColor: #0A0B1E`.

---

## 11. Asset Inventory

### Logo

| Asset | Figma Node | Image Hash | Usage |
|-------|-----------|------------|-------|
| UF Logo (PNG) | `32:5` | `bcd84e7f71b8e00eca17d5556160e73b80b68960` | All logo placements |

**Logo sizes used:**
- 120×120pt — Splash screen (large, centred)
- 52×52pt — Auth flow screens (small, top-centred)
- 34×34pt — Home screen navigation bar (compact)

### Icon Vectors (SVG Paths)

All icons are drawn as `figma.createVector()` paths with `strokeCap: ROUND`, `strokeJoin: ROUND`. Exported as SVG for implementation.

| Icon | Path Data | Stroke Color | Used In |
|------|-----------|--------------|---------|
| Transfer / double-arrow | `M 4 9 L 28 9 M 22 3 L 28 9 L 22 15 M 32 27 L 8 27 M 14 21 L 8 27 L 14 33` | `#00E5C3` | Service cell, FAB |
| SADAD / document | `M 7 3 L 25 3 C 27 3 29 5 29 7 L 29 33 … M 9 13 L 23 13 …` | `#9973FF` | Service cell |
| Qattah / card | `M 3 9 C 3 7 5 5 7 5 L 29 5 … M 3 13 L 33 13 …` | `#33D18C` | Service cell |
| Traffic / light | `M 13 2 L 23 2 C 25 2 27 4 27 6 L 27 30 … circles` | `#FFB800` | Service cell |
| Request / person+ | `M 13 14 C 16 14 18 11.7 …circle+plus` | `#F44343` | Service cell |
| More / grid | `M 9 9 L 15 9 L 15 15 L 9 15 Z M 21 9 …` | `#B2B5D0` | Service cell |
| Send arrow | `M 4 10 L 16 10 M 11 5 L 16 10 L 11 15` | `#00E5C3` | Quick action |
| Receive arrow | `M 16 10 L 4 10 M 9 5 L 4 10 L 9 15` | `#9973FF` | Quick action |
| Scan frame | `M 3 6 L 3 3 L 6 3 M 14 3 L 17 3 … M 7 7 L 13 7 L 13 13 L 7 13 Z` | `#33D18C` | Quick action |
| Pay / house | `M 4 8 L 10 3 L 16 8 L 16 17 L 4 17 Z M 8 17 L 8 12 L 12 12 L 12 17` | `#FFB800` | Quick action |
| Bell | `M 9 15 C 9 16 9.9 16.8 11 16.8 … M 7 8 C 7 5.8 9.2 4 12 4 …` | `#B2B5D0` | Nav / notification |
| Arrow-up | `M 10 16 L 10 4 M 6 8 L 10 4 L 14 8` | `#0A0B1E` | Top Up button |
| Clock | `M 10 7 L 10 11 L 13 11 M 10 3 C 6.7 3 4 5.7 4 9 …` | `#00E5C3` | History button |
| Home | `M 2 9 L 11 2 L 20 9 L 20 20 … door cutout` | `#00E5C3` (active) / `#B2B5D0` | Bottom nav |
| Card | `M 2 6 C 2 4.3 3.3 3 5 3 L 19 3 … M 2 8 L 22 8 …` | `#B2B5D0` | Bottom nav |
| Cart | `M 2 2 L 4 2 L 6 13 … circle wheels` | `#B2B5D0` | Bottom nav |
| Person | `M 11 11 C 13.8 11 16 8.8 16 6 … M 1 21 C 1 16.6 5.5 13 …` | `#B2B5D0` | Bottom nav |
| Transfer (FAB) | `M 3 7 L 19 7 M 14 2 L 19 7 L 14 12 M 19 14 L 3 14 M 8 9 L 3 14 L 8 19` | `#0A0B1E` | FAB button |

### Figma Page Structure

| Page | Contents |
|------|----------|
| 🎨 Design System | Color swatches, typography scale, logo source |
| 🔐 Auth Flow — EN | S1 Splash · S2 Welcome · S3 OTP · S4 Biometric · S5 Passcode |
| 🔐 Auth Flow — AR | S1–S5 Arabic RTL variants |
| 🏠 Home Screen — EN | S6 Home (dark) |
| 🏠 Home Screen — AR | S6 Home Arabic RTL (dark) |

---

*This document covers the complete dark theme implementation for the UF E-Wallet auth flow and home screen. Next sprint: Top Up screen, Transfer flow, Cards screen, Transaction History, and the Light theme.*