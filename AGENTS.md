# Agent notes for Devastator 2

Sequel to the Devastator port (../devastator, published at
github.com/wells01440/devastator). Design is settled and lives in
DESIGN.md — that file is the spec; do not re-litigate settled decisions,
raise conflicts with the owner instead.

## State

Grey-box round 6, playable. Round 1 shipped the six milestone steps.
Round 2 added motion, streaming junk, the flat floor, and the monorail.
Round 3 inverted the polarity: the rail is home base with normal
controls, off-rail is the wonky off-script state; junk is shootable.
Round 4 made it a lane game (owner: "almost a tempest feel"): three
rails, racers ride them too. Round 5 moved the side rails to the wall
centers and put all junk on lanes. Round 6 fixed the world model: one
perspective for everything in the slot.

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

Current gameplay:

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
- Racers follow the same mechanics (owner's call). The Skimmer spawns
  on a rail, rides it, and hops to an adjacent lane every
  Tuning.skimmerHopIntervalSeconds plus jitter. A railed pod bodily
  blocks its own lane: a Skimmer arriving there cannot pass; it clangs,
  gives back Tuning.blockKnockbackSeconds of pass clock, and is forced
  to hop. Passing needs a lane you are not holding.
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
became streaming shootable junk; the three-lane monorail system is new
and is home base for both sides, replacing the weave with lane hops and
adding lane blocking; the view is 2D rear-forward, so pseudo-3D row
scaling may be cut. Gravity recenter reads as a natural fit for an
analog stick (owner); pads arrive later via GameController. Owner likes
the double-tap-down dismount and the Tempest read.

Feel candidates for the pass: the two dismounts, the hop cadence,
blockKnockbackSeconds, wonkAimDrag, aimFollowLag,
gravityRecenterPerSecond, gravityGraceSeconds, crosshairSpeed,
hitRadius, the rail constants, the junk cadence.

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
