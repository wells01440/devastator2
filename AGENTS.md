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
owner. "DS era" means that era of graphics only, never the dual-screen
form: no info screen, no bottom panel. The debug line is gone; any
future HUD is diegetic, in the world. Pass 1 (done): Palette.swift
role colors, Sprites.swift pixel-art sprites (nearest filtering, 2
scene points per art pixel), starfield, horizon glow, lit bevel facets
on the slot's cut faces, hot rails with glow, reticle, engine glow
while railed, kill fragments. Pass 2 (done): Earth big — it hangs over
everything, it is the point; junk is battle debris (wing, hull chunk,
girder, bits) in varied sizes; the aim is caged inside the slot
(clampAim: between the walls, above the track, below the rim), which
is the Tempest feel. Pass 3 (done): Earthrise — a 32x32 Earth at 96pt
with clouds, desert, deep ocean and a night-side terminator, its lower
limb occluded by the horizon and the slot's interior fill; the slot
expanded to the usable frame (wallInset 44, rim 308, floor 40, rails
at +-160); busy lunar terrain (horizon mounds, craters, dirt speckle);
alien skeletons buried in the dirt, Dig Dug style (Tuning
skeletonSpots); the opponent is a detailed frisbee UFO with a glass
dome, running lights, and tractor glow. Pass 4 (done): parallax and
urgency — three streamer layers pour out of the vanishing point at
forward speed (surface craters on the cap band fastest, wall streaks,
additive rail pulses fastest of all as energy), the pod rumbles and
its engine flickers while railed, and the depth stripes thickened.
Railing doubles the whole world's rush through forwardScale. Pass 5
(done): the era jump from 80s wireframe to 2010 DS — the tube is
FILLED: flat-shaded panel bands per wall falling into depth fog
(Tuning.tubeBandCount, fogStrength), earthlight bias on the left
walls, additive light strips running each rail into the mouth
(brighter under the seated pod), the wireframe lane rays deleted, seam
lines dimmed to segment joints, the mouth softly filled. Surfaces,
not edges. Pass 6 (done): working resolution doubled where it counts —
pod and UFO redrawn at one scene point per art pixel, junk replaced
with big detailed hazard-striped wrecks (transit car, downed saucer,
girder tangle); bright light-ring fixtures sweep the tube; station
stops slide past (platform, window band, lit sign,
Tuning.stationIntervalSeconds); the roof slot got its glass canopy (a
glazed sheet down the tube plus a near band with glints — cut-scene
real estate) with the HUD projected on it: LAUNCH T-x.x going red
inside Tuning.hudUrgentSeconds, and hull pips. Pass 7 (done): combat
depth and grit — three-hit UFO with fly-off fragments and hull
scorches, rail-gun return fire, gun/shield pickup chips on the lanes,
P1/P2 scores with brink-multiplied kill popups, gun pips on the glass
opposite the hull pips, glass slashes down the glazed roof, stations
on all five rails from Tuning.stationFirstSeconds, panel grunge down
the bore, regolith boulders, more mounds and craters, and an
atmosphere halo on the Earthrise. Remaining passes, roughly in order:
brink-time danger reddening, level palette themes, cut-scene beats,
the sound pass (music per Assets/Music/MANIFEST.md, slo-mo whoosh,
notch clicks), pads via GameController.

Controls: left/right move around the ring, space fires down the tube,
double-tap up jumps, Q quits. Release near a rail to click in; pull
and hold to pop out. That is the whole scheme.

Settled gameplay (the TUBE model, the owner's revision of the
grey-box outcome — "aiming should be side to side only"):

- The world: the lunar transit system. A hexagonal bore
  (Tuning.hex...) whose roofline is open to the surface — through the
  slot: stars and the Earthrise. Five hot rails sit at the five wall
  centers; the roof carries none. The bad guys hijack the same tubes;
  junk is wrecked hardware sitting on the lanes. One perspective
  serves everything: projectPoint converges on the far mouth at the
  bore's center (Tuning.farPointScale, depthExponent); far is small,
  near is big, nothing flies. 2D rear-forward always.
- ONE AXIS. Left/right shuttles the pod around the railed perimeter
  (Tuning.podPerimeterSpeed); position IS aim. The pod and the UFO
  bank to the walls (zRotation follows each wall). Gravity slides an
  idle pod toward the floor rail after Tuning.gravityGraceSeconds and
  it clicks into notches on the way down.
- Notches: released near a rail, the pod settles in and clicks
  (Tuning.railSnapDistance). Railed = fast (railScrollScale, chase
  clock at railClockScale) and steady. A sustained directional pull
  pops the notch (Tuning.railStickSeconds); coasting between rails is
  slow. notchCooldownSeconds prevents an instant re-click.
- Jumps: single up-tap hops; clearance is the jump arc against the
  wreck's height (Tuning.junkClearanceFactor), so small bits clear
  almost anywhere in the arc and big wreckage needs the top of the
  jump. A second up-tap in the window is the BIG JUMP: a committed
  slo-mo leap (Tuning.bigJumpSloMo on the world clock) to the opposite
  wall's rail, flipping through the bore; off the floor, whose
  opposite face is the open roof, it goes straight up and back. The
  big jump clears all junk. Sound pass owes it a whoosh. The
  double-down spike is CUT (owner: simpler play); down does nothing.
- The hull: Tuning.hullMax pips on the glass HUD; junk costs one plus
  the stun; empty resets full with Tuning.invulnSeconds of grace.
- The shot goes straight down the tube to the end and owns
  Tuning.laneHitWidth of the ring: every junk piece in the line dies,
  and the UFO dies if its perimeter position is in the line, mid-hop
  included. The sight beam (always on, faint) shows your firing line
  ending at the far mouth; it brightens over junk and goes
  enemy-marker red when the UFO is in the line.
- The chase: the UFO spawns close ahead (skimmerSpawnDepth), rides
  rails, hops adjacent lanes, and runs for the far mouth. Clock out =
  kablammo: sky flash, a pass. Mercy brake once per racer when passes
  exceed kills. It takes Tuning.skimmerHitsToKill hits; each hit
  staggers the getaway (skimmerHitKnockbackSeconds), knocks fragments
  off, and leaves a scorch on the hull. The escape-clock ring is gone;
  LAUNCH T- on the glass is the clock.
- Return fire: the UFO shoots a rail-gun bolt straight down its own
  lane (skimmerShootIntervalSeconds + jitter, boltDepthPerSecond).
  Sharing its lane is the duel: both can hit. Any air clears a bolt.
- Pickups splatter the lanes (Tuning.pickupIntervalSeconds) and are
  caught on the ground: point chips (pointsChipValue), gun chips (to
  gunLevelMax damage), shield chips (to hullPickupCap), and multiplier
  chips. Every HIT on the saucer sheds a multiplier chip at its depth
  ("especially off the ship"); catching one raises the score
  multiplier to Tuning.chainMax. Damage resets the multiplier; hull
  empty resets hull AND gun.
- Scoring: kills pay baseKillScore x brink (Tuning.brinkTiers) x the
  multiplier; point chips pay value x multiplier; popups at the
  source. P1 bottom-left with the live multiplier, P2 placeholder
  bottom-right (2P pending).
- The DEVASTATOR: a brink kill banks one charge (lamp on the glass by
  the launch clock); DOWN fires it — full-screen flash, every junk
  piece and bolt dies, the saucer dies with full scoring.
- Turbo gates (Tuning.turbo...): chains of glowing pads arrive every
  turboChainIntervalSeconds on a lane-switch pattern. Ride every pad
  in the chain and turbo fires: the world at turboScrollScale and the
  chase clock REWINDING (turboEscapeScale) — you catch the quarry.
  Missing any pad breaks the chain.
- The UFO is bigger still, spawns closer (skimmerSpawnDepth), and
  SPINS (running lights slide across the band). Hits flash the hull
  white and deplete red hp pips over the dome. Its return fire is
  telegraphed (boltTelegraphSeconds of orange strobing before the
  shot), slower (boltDepthPerSecond), and narrower than your shot
  (boltHitWidth), so the answer is a hop timed in place. Incoming junk
  is caught by a green radar crosshair flashing ON the piece until it
  is halfway in (junkPingDepth).
- The train read: cockpit frame pillars and a dashboard band around
  the screen, a headlight cone from the pod down the dark tube, wall
  conduits running the bore's length, four light-ring fixtures, and
  stations every Tuning.stationIntervalSeconds as real platforms:
  slab, lit window row, pillars, pulsing sign. The hull carries its
  own shield pips (podShieldPips) as asked, alongside the glass HUD.
- Turbo gates are big, green, pulsing, and spawn one at a time from
  the mouth (turboPadGapSeconds apart) so the chain reads as a
  pattern to ride.
- Junk sits on lanes only, closes at your forward speed (doubled
  railed), stuns on contact (controls cut, hard gravity to the floor
  rail, fire disabled) and derails; jump it, shoot it, or wear it.
- Two-player intent: both pods ride the same ring, offset front to
  back a little, so side-to-side movement does not collide. The buddy
  pod renders at a slightly farther depth when built.

DESIGN.md deltas (owner-directed; fold into DESIGN.md when it gets its
rewrite): free 2D aim is CUT — one-axis movement, position is aim; the
trench became the hexagonal transit tube with five rails and an open
surface side; enemies flee rather than approach; junk is stationary
shootable wreckage; the view is 2D rear-forward with scale-by-depth.
An escape resolves as the kill-shot cut scene, as DESIGN.md always had
it; losing vertical aim changes nothing there. Pads later via
GameController. Owner ideas parked: thrown junk (at you, or up in the
air), the Groove reshaping over time (rail positions moving), race
mode. Two-player: front-to-back offset on the same ring.

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
