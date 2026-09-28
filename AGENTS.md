# Agent notes for Devastator 2

Sequel to the Devastator port (../devastator, published at
github.com/wells01440/devastator). Design is settled and lives in
DESIGN.md — that file is the spec; do not re-litigate settled decisions,
raise conflicts with the owner instead.

## State

Grey-box round 2, playable. Round 1 shipped the six milestone steps;
the owner's first feel pass asked for motion, moving obstacles, a flat
floor with sloped sides, and the monorail. All are in. The core round-1
complaint was fighting the aim; the rail and the gravity grace are the
answers under test.

## Layout

| Path | Holds |
|---|---|
| DESIGN.md | the gameplay spec, settled through four design rounds |
| Package.swift | SPM executable target, macOS 13+ |
| Sources/Devastator2/main.swift | AppKit bootstrap: window + SKView |
| Sources/Devastator2/GameScene.swift | the grey-box scene; disposable |
| Sources/Devastator2/Tuning.swift | every gameplay number; nothing numeric hides elsewhere |
| Assets/Music/ | 12 curated tracks + MANIFEST.md; not bundled yet |

## Build and run

- `swift build` — compile check.
- `swift run` — opens the window. Q quits. Opens in the foreground;
  build-check with `swift build` when the owner is working.
- Xcode: open Package.swift directly.
- No FutureBasic here. The FB lessons in ../devastator/AGENTS.md apply
  only to that repo. The original's sprite bytes (for homage quotes like
  the Earth-shatter frames) are in ../devastator/Devastator/GameData.incl.

## Current milestone: the feel pass

The grey-box answers whether aim-as-movement feels good. Nothing ships
from it. `swift run`: arrows move the crosshair, the pod chases its
horizontal position along the trench floor, gravity recenters both
after Tuning.gravityGraceSeconds of idle. Space fires; a hit needs the
crosshair on the Skimmer. The clock expiring counts a pass and flashes
the sky band. Q quits. The debug line bottom-left shows kills, passes,
the pass clock, and RAIL or STUN state.

Round 2, from the owner's first feel pass:

- Trench profile is a flat floor with straight sloped sides
  (Tuning.flatHalfWidth).
- Motion: transverse track stripes sweep from the far rim to the near
  surface at Tuning.trackScrollPerSecond.
- The fixed obstacle is replaced by streaming junk: pieces spawn every
  Tuning.junkSpawnSeconds, race down the trench, and slide past. Junk
  arriving on the pod stuns it (Tuning.stunSeconds): controls cut,
  gravity drags the aim home hard, fire disabled.
- The monorail runs down the floor center. Snap on by putting pod and
  aim on the line. While railed: the pod locks to the rail and the aim
  is free (the answer to fighting the aim), the pass clock drains at
  Tuning.railClockScale, stripes scroll at Tuning.railScrollScale. The
  lock: leaving takes a sustained aim pull past Tuning.railBreakDistance
  for Tuning.railBreakSeconds, junk favors the rail lane
  (Tuning.railJunkChance), and a hit stuns and derails.

DESIGN.md deltas pending the owner's verdict: fixed obstacles as cover
are out of the grey-box in favor of streaming junk, and the monorail is
new. Fold both into DESIGN.md once the owner confirms the feel. Gravity
recenter reads as a natural fit for an analog stick (owner); pads
arrive later via GameController.

The flat reading of the trench: the profile is the near cross-section;
Skimmer and junk descend from the rim (far) to the track surface (near).
Pseudo-3D row scaling replaces this later.

Feel candidates for the pass: aimFollowLag, gravityRecenterPerSecond,
gravityGraceSeconds, crosshairSpeed, hitRadius, the rail constants, the
junk cadence.

Rules while the grey-box lives: every constant goes in Tuning.swift;
keep the scene tree flat and disposable; no music, no art, no score
display beyond the debug line.

After the feel pass: pseudo-3D row scaling, scoring with brink tiers,
more racer types.

## Conventions

- Swift, SpriteKit, AVAudioEngine, GameController. Platform-native
  only; no third-party packages without the owner's say.
- No magic numbers outside Tuning.swift.
- Music: read Assets/Music/MANIFEST.md before touching audio. Slot
  assignments there are provisional until the owner's ear pass. Never
  edit the MP3s in place; masters live in the bugthing project.
- Owner's global style rules apply to all text (terse, factual, no
  concessive compounds, no em dashes).
