# Agent notes for Devastator 2

Sequel to the Devastator port (../devastator, published at
github.com/wells01440/devastator). Design is settled and lives in
DESIGN.md — that file is the spec; do not re-litigate settled decisions,
raise conflicts with the owner instead.

## State

Grey-box playable. All six milestone steps are in: flat U trench, aim-led
pod with gravity recenter, one weaving Skimmer with a shrinking pass
ring, space to fire, one obstacle the aim routes over. The owner's feel
pass is next; expect Tuning churn.

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
horizontal position along the U, gravity recenters both when input is
idle. Space fires; a hit needs the crosshair on the Skimmer. The
obstacle blocks the pod unless the aim is above it by
Tuning.obstacleClearance, which routes the pod over the top. The clock
expiring counts a pass and flashes the sky band. Q quits. The debug
line bottom-left shows kills, passes, and the pass clock.

The flat reading of the trench: the U is the near cross-section, the
Skimmer descends from the rim (far) to the track surface (near) over
Tuning.passClockSeconds. Pseudo-3D row scaling replaces this later.

Feel candidates for the pass: aimFollowLag, gravityRecenterPerSecond,
crosshairSpeed, hitRadius, skimmerWeaveAmplitude, skimmerWeaveHz.

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
