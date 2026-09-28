# Agent notes for Devastator 2

Sequel to the Devastator port (../devastator, published at
github.com/wells01440/devastator). Design is settled and lives in
DESIGN.md — that file is the spec; do not re-litigate settled decisions,
raise conflicts with the owner instead.

## State

Grey-box gameplay ACCEPTED by the owner ("the chase is it") after seven
feel rounds; the round history is in git log. The graphic build is in
progress: first art pass landed (palette, pixel-art sprites, lit
trench, sky). Mechanics are settled as described below; visual work
continues.

## Layout

| Path | Holds |
|---|---|
| DESIGN.md | the gameplay spec, settled through four design rounds |
| Package.swift | SPM executable target, macOS 13+ |
| Sources/Devastator2/main.swift | AppKit bootstrap: window + SKView |
| Sources/Devastator2/GameScene.swift | the scene: mechanics settled, visuals evolving |
| Sources/Devastator2/Tuning.swift | every gameplay number; nothing numeric hides elsewhere |
| Sources/Devastator2/Palette.swift | every color, by role; level-1 lunar dawn values |
| Sources/Devastator2/Sprites.swift | pixel-art sprites as C64-style string maps |
| Assets/Music/ | 12 curated tracks + MANIFEST.md; not bundled yet |

## Build and run

- `swift build` — compile check.
- `swift run` — opens the window. Q quits. Opens in the foreground;
  build-check with `swift build` when the owner is working.
- Xcode: open Package.swift directly.
- No FutureBasic here. The FB lessons in ../devastator/AGENTS.md apply
  only to that repo. The original's sprite bytes (for homage quotes like
  the Earth-shatter frames) are in ../devastator/Devastator/GameData.incl.

## Current milestone: the graphic build

Grey-box gameplay is accepted; do not change mechanics without the
owner. The DS-era look lands in passes. Pass 1 (done): Palette.swift
role colors, Sprites.swift pixel-art pod/Skimmer/junk/Earth (nearest
filtering, 2 scene points per art pixel), starfield and Earth in the
sky, horizon glow, lit bevel facets on the slot's cut faces, hot rails
with glow, reticle crosshair, engine glow while railed, kill
fragments. Remaining passes, roughly in order: brink-time danger
reddening, level palette themes, richer trench dressing and parallax,
a real HUD replacing the debug line, cut-scene beats, music through
AVAudioEngine per Assets/Music/MANIFEST.md, pads via GameController.

Controls: arrows aim, space fires, double-tap up hops, double-tap down
slam-locks or clunks off, Q quits. The debug line bottom-left shows
kills, passes, the chase clock, and RAIL/BRAKE/STUN state.

Settled gameplay (the grey-box outcome):

- The world model (owner's spec): you are slotted into a trench on the
  moon with three hot rails; the bad guys are in the same slot, on the
  same rails, and they do not fly; junk is stationary wreckage sitting
  on the tracks. One perspective serves everything: GameScene.project
  maps a lane position and a depth to a screen point converging on the
  horizon (trench center at rim height) and a scale — far is small,
  near is big (Tuning.farPointScale, Tuning.depthExponent). The view
  stays 2D rear-forward ("not the 3d rendering, just the two-d").
- Stationary junk closes at the pod's forward speed
  (Tuning.trackScrollPerSecond), doubled while railed: going fast
  makes the wreckage loom twice as fast. Shoot it out of the way or
  take the hit. Thrown junk (at you, or up in the air) is designed but
  deferred; today the only junk is on the tracks.
- Three rails, Tempest positions (Tuning.railOffsetsX): the center of
  the left wall, the floor, the center of the right wall. Each is a
  bump riding the profile, with a faint lane line running from the far
  rim into it. A rail is home base. Ride the pod onto a bump with the
  aim near it and it notches in: jolt, spark, RAIL L/C/R in the debug
  line. Railed, the controls are normal: direct aim, no gravity, the
  pod holds the rail. The pass clock drains at Tuning.railClockScale
  and stripes scroll at Tuning.railScrollScale (the go-fast).
- The chase: the Skimmer spawns close ahead (Tuning.skimmerSpawnDepth),
  rides the rails, hops lanes, and RUNS AWAY, shrinking toward the
  horizon. The pass clock is the chase clock; if it drains, he made the
  distance and it is kablammo (sky flash, a pass). Railing keeps pace
  (Tuning.railClockScale); braking loses ground
  (Tuning.brakeEscapeScale). Mercy: a fleeing racer eases off once
  (Tuning.skimmerBrakeSeconds) when passes exceed kills.
- The hop pair. Double-tap up: the pod jumps (Tuning.podHopSeconds/
  Height) and sails over arriving junk. Double-tap down off a rail:
  slam lock into the nearest rail with a hard brake
  (Tuning.brakeSeconds, BRAKE in the debug line); double-tap down on a
  rail: clunk off.
- The lane blast: railed, with the aim on your own lane line
  (Tuning.laneShotTolerance), a shot runs the whole lane and destroys
  every junk piece on it, plus the Skimmer if he is riding that rail
  and not mid-hop.
- Off-rail is off script: slower scroll, and the controls go wonky
  because yaw, pitch, and aim are one input; the pod's motion smears
  the crosshair by Tuning.wonkAimDrag. Gravity pulls the aim down to
  trench level and, from the slopes, in toward the flat area only; it
  does not drag you to center from the flat.
- Two ways off the rail, both under test: shove the aim hard to a
  screen edge and hold (port/starboard clunk toward that side), or
  double-tap down (clunk off in place).
- Junk sits only on the three lanes; a piece arriving on the pod stuns
  (controls cut, hard gravity, fire disabled) and derails. Off-rail
  floor space is junk-free, so hiding between lanes is safe and slow.

DESIGN.md deltas pending the owner's verdict: fixed obstacles as cover
became stationary shootable track junk; the three-lane monorail system
is home base for both sides; enemies flee rather than approach, so
"passing" is now escaping down-slot; the view is 2D rear-forward with
scale-by-depth. Gravity recenter reads as a natural fit for an analog
stick (owner); pads arrive later via GameController. Owner likes the
double-tap-down dismount and the Tempest read. Owner ideas parked for
later: thrown junk (at you, or up in the air), and the Groove reshaping
over time (notch shape changing, rail positions moving).

After the graphic passes: scoring with brink tiers and the chain,
banked DEVASTATOR, more racer types, the buddy pod, levels.

## Conventions

- Swift, SpriteKit, AVAudioEngine, GameController. Platform-native
  only; no third-party packages without the owner's say.
- No magic numbers outside Tuning.swift. Colors live in Palette.swift
  by role; pixel art lives in Sprites.swift as string maps. Shape-path
  ratios (the reticle) count as art, not magic numbers.
- Music: read Assets/Music/MANIFEST.md before touching audio. Slot
  assignments there are provisional until the owner's ear pass. Never
  edit the MP3s in place; masters live in the bugthing project.
- Owner's global style rules apply to all text (terse, factual, no
  concessive compounds, no em dashes).
