# Devastator 2 — gameplay design

Working draft for conversation. No code exists. Items marked (W) are
Wells's calls; unmarked items build on them.

## Premise

The Devastator mothership is back, parked in lunar eclipse. Earth's last
defense is the Groove (W): a railgun trench cut into the moon's surface.
You are slotted into a gun pod that rides the trench (W). Earth hangs in
the sky above the trench, same as the original's backdrop, except now you
are standing on the moon looking back at what you are defending.

Enemy pods race the trench and try to get PAST you (W: pod race / slot
race). Any pod that passes climbs out of the trench, arms, and launches a
missile at Earth (W). The original's rule survives intact: you get about
ten seconds per enemy, and the reason is now diegetic — that is how long
a pod takes to out-run you.

The Groove matches the music (W): track lights, obstacles, and enemy
spawns ride the soundtrack's beat grid.

## Core loop

1. A level begins: ten opponents (W).
2. Aim the crosshair; your pod slides along the U to follow it.
3. Kill each pod before it passes you. Dodge track junk and thrown junk.
4. A pod that passes climbs to the sky band, armored, and starts an arm
   countdown. Hits up there stagger it and stretch the countdown; strip
   the armor to kill it. While your aim is in the sky, the trench runs
   unguarded.
5. A launched missile plays the kill-shot cut scene and costs Earth one
   shield segment. Lose all three and the Devastator finishes Earth.
6. Ten opponents down: level up — palette and music change (W), next
   level is faster.

## The pod: health and stun (W: stunned, with a life level)

- The pod has a life bar. It is damaged by track junk it plows into and
  by junk the enemies throw back at you (W).
- A damaging hit stuns: controls cut out for a beat and lunar gravity
  drags the crosshair and pod back to the bottom of the U. The penalty
  is positional, not just numeric — you recenter whether you like it or
  not.
- Life empty: pod offline for a long respawn while the track runs
  unguarded. Earth's shields remain the only lose condition.

## Movement: aim-led pod with lunar gravity (W)

- Arrows (or stick) move the crosshair in 2D.
- The pod chases the crosshair's horizontal position along the U with a
  short lag. Gravity eases both pod and crosshair back toward the bottom
  of the U when input is idle (W).
- Fixed obstacles sit in the trench — wreckage, coolant towers, dead
  pods (W). The pod cannot pass through them; aim path is movement path,
  so you route the aim up and over. Plowing into junk costs life.
- Obstacles are cover for both sides: enemy pods duck behind them, and
  shots do not pass through them.

## Turbo and the ram (W: collectables, no extra buttons)

- Speed-up collectables sit in the trench. Driving your aim through one
  triggers turbo: a short burst where the pod accelerates and contact
  kills — the ram mechanic without a ram button (W).
- During turbo the pod shrugs off junk. Ramming a Shell staggers it
  instead of killing.
- No new controls, so the two-player button budget stays intact (W).

## Enemies (W: smarter than bouncing)

Racers read your pod position — and since your pod follows your aim,
they are effectively dodging your crosshair. The duel is aim versus
feint. Racers also throw junk back down the trench at you (W).

| Type | Behavior | Introduced |
|---|---|---|
| Skimmer | steady racer, gentle weave | level 1 |
| Feinter | fakes a lane change when your aim commits | level 2 |
| Shell | armored, three hits, slow, blocks shots for pods behind it | level 3 |
| Splitter | splits into two fast minis on death | level 4 |
| Cloaker | shimmer-visible except near the crosshair | level 6 |
| Pace pod | mini-boss every fifth level; shields racers drafting it | level 5, 10, ... |

Final level: the Devastator itself descends into the trench.

## Timing and scoring (W: exponential near zero)

Each enemy carries its own 10-second pass clock, visible as a shrinking
ring around it.

- Base kill: 10 points (heritage).
- Brink bonus: kills multiply as the clock drains — x2 in second 8, x4
  in second 9, x8 in the final second, x16 inside the last half second.
- Chain multiplier (W): consecutive kills without a pass build x1
  through x5. A pass resets it.
- Total = base x brink x chain. Score popups at the kill point; the
  brink tier changes the popup color and sound pitch.

## The DEVASTATOR (W: a blow-up-all-things attack)

Your railgun's overcharge. The meter fills only from brink bonuses, so
the super is earned by playing close to the wire.

- Fired with a dedicated key. The shot shatters every enemy in the
  trench; wrecks ricochet as secondary fragments that sweep the sky band
  too (W: secondary asteroids). Fragment kills score at current
  multipliers.
- Full-screen palette flash, the one moment the game goes loud.

## Levels, difficulty, theming

- A level is ten opponents (W). Level-up changes the palette theme and
  the music (W), then raises enemy speed, simultaneous racers, junk
  density and throw rate, and shortens the sky-band arm time.
- Palette arc across levels: lunar dawn greys, hard noon white, dusk
  amber, earthlight blue-black. Danger override: the world reddens in
  brink time, inverting during a DEVASTATOR.
- 1/2/3 heritage keys pick the starting level.

## Story beats and cut scenes (W)

- Intro: eclipse reveal, pod drop, clamp-in — the slotted-in moment.
- Kill shot (W): the escaped pod launches. The missile shrinks toward
  Earth. Impact — then nothing. The trench sits silent for the 1.3
  seconds light needs to come back from Earth, and only then does the
  flash wash over the lunar surface and your cockpit (W: wait the
  light-seconds, then kablammo).
- Shield-gone: the death bolt, same light-lag beat at full scale. The
  Earth explosion quotes the original's three-frame globe shatter as the
  final frames.
- Victory: the Devastator's core exposed in the trench, your overcharge
  ends it.
- Interstitials between levels stay under three seconds and are
  skippable.

## Sound (W: music, soundtrack)

- Adaptive score: base synthwave layer, a percussion layer that enters
  when any pod crosses half-track, a lead layer in brink time. The music
  is the timer you can hear.
- Each level-up swaps the track with the theme (W); the Groove's
  geometry pulses on its beat grid.
- The original's 445-535 Hz siren warble returns as the bassline motif.
- SID-flavored instruments; kill, brink, pass, stun, and turbo each get
  a signature sound.

## Look (W: Nintendo DS era)

- 2.5D: low-poly flat-shaded trench receding to the horizon, sprite
  enemies, parallax Earth and starfield. Internal resolution around
  256x192 scaled up, 60 fps. Chunky but lit.
- The trench IS the original's corridor backdrop, made literal and
  three-dimensional.

## Engine

Recommendation: Swift + SpriteKit, with AVAudioEngine for the adaptive
score and the GameController framework for pads. Xcode project.

Why this over the alternatives:

- Platform-native, free, App Store viable, current WWDC guidance.
- Adaptive music is the deciding feature. AVAudioEngine runs beat-locked
  layer players with volume automation; nothing in FutureBasic's sound
  statement or NSSound comes close.
- The DS-era look maps to SpriteKit directly: row-scaled sprites for the
  pseudo-3D trench (how the DS actually did it), SKShader fragment
  shaders for per-level palette grading and the DEVASTATOR flash,
  particle emitters for fragments and junk.
- Cut scenes are in-engine SKAction sequences — skippable, no video
  assets.
- xcodebuild gives a scriptable command-line build and test loop. The
  port's single biggest friction was FutureBasic's GUI-only build.

Considered and set aside:

- FutureBasic again: right for the heritage port; the sequel's audio,
  shaders, and 2.5D would be fought uphill. Its lessons stay in
  ../devastator/AGENTS.md.
- FB hosting an SKView: possible, but SpriteKit through toolbox
  bindings adds friction with none of Swift's tooling.
- SceneKit / true 3D: more engine than a DS-era look needs; revisit only
  if row-scaling reads badly in prototype.
- Godot / Unity / SDL: capable, but third-party runtimes against a
  platform-native house style, and Unity brings licensing noise.

First technical milestone when design settles: a grey-box trench with
aim-led pod movement and one Skimmer, to test whether aim-as-movement
feels right. Everything else hangs off that feel.

## Open questions for conversation

1. Two-player: the original's asymmetric duel (P2 flies a racer) — same
   screen? alternating levels? P2's controls with the current button
   budget?
2. DEVASTATOR trigger key, and whether charges bank.
3. Pod life size: hits-to-offline, and respawn length.
4. Sky-band armor: how many hits, and how much time per stagger.
5. Session length: how many levels to credits, endless after?
6. Do turbo collectables spawn on the beat grid?
