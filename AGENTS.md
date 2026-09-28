# Agent notes for Devastator 2

Sequel to the Devastator port (../devastator, published at
github.com/wells01440/devastator). Design is settled and lives in
DESIGN.md — that file is the spec; do not re-litigate settled decisions,
raise conflicts with the owner instead.

## State

Grey-box round 3, playable. Round 1 shipped the six milestone steps.
Round 2 added motion, streaming junk, the flat floor, and the monorail.
Round 3 inverted the polarity on the owner's second feel pass: the rail
is home base with normal controls, off-rail is the wonky off-script
state. Junk is shootable.

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

Round 3 gameplay, per the owner's second feel pass:

- The view is the 2D rear-forward cross-section (owner's call, "not the
  3d rendering, just the two-d"). The rail is a bump on the floor at
  center (Tuning.railBumpHalfWidth/Height), not a depth line.
- The rail is home base. Ride the pod onto the bump with the aim near
  center and it notches in: jolt, spark, RAIL. Railed, the controls are
  normal: direct aim, no gravity, the pod holds the rail. The pass
  clock drains at Tuning.railClockScale and stripes scroll at
  Tuning.railScrollScale (the go-fast).
- Off-rail is off script: slower scroll, and the controls go wonky
  because yaw, pitch, and aim are one input; the pod's motion smears
  the crosshair by Tuning.wonkAimDrag. Gravity pulls the aim down to
  trench level and, from the slopes, in toward the flat area only; it
  does not drag you to center from the flat.
- Two ways off the rail, both under test: shove the aim hard to a
  screen edge and hold (port/starboard clunk toward that side), or
  double-tap down (clunk off in place).
- Junk streams down the trench and is shootable out of the way; a
  piece arriving on the pod stuns (controls cut, hard gravity, fire
  disabled) and derails. Junk favors the rail lane
  (Tuning.railJunkChance).

DESIGN.md deltas pending the owner's verdict: fixed obstacles as cover
became streaming shootable junk; the monorail is new and is home base;
the view is 2D rear-forward, so pseudo-3D row scaling may be cut.
Gravity recenter reads as a natural fit for an analog stick (owner);
pads arrive later via GameController.

Feel candidates for the pass: the two dismounts, wonkAimDrag,
aimFollowLag, gravityRecenterPerSecond, gravityGraceSeconds,
crosshairSpeed, hitRadius, the rail constants, the junk cadence.

Rules while the grey-box lives: every constant goes in Tuning.swift;
keep the scene tree flat and disposable; no music, no art, no score
display beyond the debug line.

After the feel pass: scoring with brink tiers, more racer types, and a
depth treatment that keeps the 2D rear-forward view.

## Conventions

- Swift, SpriteKit, AVAudioEngine, GameController. Platform-native
  only; no third-party packages without the owner's say.
- No magic numbers outside Tuning.swift.
- Music: read Assets/Music/MANIFEST.md before touching audio. Slot
  assignments there are provisional until the owner's ear pass. Never
  edit the MP3s in place; masters live in the bugthing project.
- Owner's global style rules apply to all text (terse, factual, no
  concessive compounds, no em dashes).
