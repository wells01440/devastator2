# Devastator 2 — gameplay design

Working draft for conversation. No code exists. Items marked (W) are
Wells's seeds; unmarked items build on them.

## Premise

The Devastator mothership is back, parked in lunar eclipse. Earth's last
defense is the Groove: a railgun trench cut into the moon's surface. You
are slotted into a gun pod that rides the trench (W: "slotted into
something, on the moon"). Earth hangs in the sky above the trench, same as
the original's backdrop, except now you are standing on the moon looking
back at what you are defending.

Enemy pods race the trench and try to get PAST you (W: pod race / slot
race). Any pod that passes climbs out of the trench, arms, and launches a
missile at Earth (W: the kill shot). The original's rule survives intact:
you get about ten seconds per enemy, and the reason is now diegetic — that
is how long a pod takes to out-run you.

## Core loop

1. A heat begins. Enemy pods enter from the trench horizon.
2. Aim the crosshair; your pod slides along the U to follow it.
3. Kill each pod before it passes you.
4. A pod that passes climbs to the sky band and starts an arm countdown.
   You can still snipe it up there — while you do, the trench runs
   unguarded.
5. A launched missile costs Earth one shield segment. Lose all three and
   the Devastator finishes Earth with the death bolt.
6. Clear the heat, watch the interstitial, next heat is faster.

## Movement: aim-led pod with lunar gravity (W)

- Arrows (or stick) move the crosshair in 2D.
- The pod chases the crosshair's horizontal position along the U with a
  short lag. Gravity eases both pod and crosshair back toward the bottom
  of the U when input is idle (W: auto-centering).
- Fixed obstacles sit in the trench — wreckage, coolant towers, dead pods
  (W: fixed objects to maneuver around). The pod cannot pass through
  them; aiming across one makes the pod bump and stall until you route
  the aim up and over. Aim path is movement path.
- Obstacles are cover for both sides: enemy pods duck behind them, and
  your shots cannot pass through them.
- Open question: does the pod collide with enemy pods? A ram kill that
  costs shield or stuns the pod could be a panic button.

## Enemies (W: smarter than bouncing)

Racers read your pod position — and since your pod follows your aim, they
are effectively dodging your crosshair. The duel is aim versus feint.

| Type | Behavior | Introduced |
|---|---|---|
| Skimmer | steady racer, gentle weave | heat 1 |
| Feinter | fakes a lane change when your aim commits | heat 2 |
| Shell | armored, three hits, slow, blocks shots for pods behind it | heat 3 |
| Splitter | splits into two fast minis on death | heat 4 |
| Cloaker | shimmer-visible except near the crosshair | heat 6 |
| Pace pod | mini-boss every fifth heat; shields the racers drafting it | heat 5, 10, ... |

Final heat: the Devastator itself descends into the trench.

## Timing and scoring (W: exponential near zero)

Each enemy carries its own 10-second pass clock, visible as a shrinking
ring around it.

- Base kill: 10 points (heritage).
- Brink bonus: kills multiply as the clock drains — x2 in second 8, x4 in
  second 9, x8 in the final second, x16 inside the last half second.
  Waiting is worth exponentially more, and exponentially riskier.
- Chain multiplier (W: multipliers): consecutive kills without a pass
  build x1 through x5. A pass resets it.
- Total = base x brink x chain. Score popups at the kill point; the
  brink tier changes the popup color and sound pitch.

## The DEVASTATOR (W: use the word for a blow-up-all-things attack)

Your railgun's overcharge. The meter fills only from brink bonuses, so
the super is earned by playing close to the wire.

- Fired with a dedicated key. The shot shatters every enemy in the
  trench; wrecks ricochet as secondary fragments that sweep the sky band
  too (W: secondary asteroids). Chain kills from fragments count toward
  score at current multipliers.
- Full-screen palette flash, the one moment the game goes loud.
- Open question: one charge held max, or bankable?

## Difficulty and theming

- Progressive (W): each heat raises enemy speed, simultaneous racers,
  obstacle density, and shortens the sky-band arm time.
- Color theming (W): the palette tracks the lunar day across heats —
  dawn greys, hard noon white, dusk amber, earthlight blue-black. Danger
  states override: the world reddens as any enemy clock enters brink
  time, inverting fully during a DEVASTATOR.
- Difficulty selection: 1/2/3 heritage keys pick starting heat rather
  than a hidden speed value.

## Story beats and cut scenes (W)

- Intro: eclipse reveal, pod drop, clamp-in — the "slotted in" moment.
- Missile launch: passed pod's kill shot — missile streaks down, Earth
  shield flare or continent scar (W: this is the story that makes the
  gameplay better).
- Shield-gone: the death bolt. The Earth explosion quotes the original's
  three-frame globe shatter as the final frames.
- Victory: the Devastator's core exposed in the trench, your overcharge
  ends it.
- Interstitials between heats stay under three seconds and are
  skippable.

## Sound (W: music, soundtrack)

- Adaptive score: base synthwave layer, a percussion layer that enters
  when any pod crosses half-track, a lead layer in brink time. The music
  is the timer you can hear.
- The original's 445-535 Hz siren warble returns as the bassline motif.
- SID-flavored instrument palette; kill, brink, and pass each get a
  distinct signature sound.

## Look (W: Nintendo DS era)

- 2.5D: low-poly flat-shaded trench receding to the horizon, sprite
  enemies, parallax Earth and starfield. Internal resolution around
  256x192 scaled up, 60 fps. Chunky but lit.
- The trench IS the original's corridor backdrop, made literal and
  three-dimensional.

## Open questions for conversation

1. Pod survivability: is the pod immortal (Earth shields are the only
   health) or can it be stunned/damaged?
2. Ram mechanic: yes or no.
3. DEVASTATOR: single charge or bankable; button choice.
4. Two-player: the original's asymmetric duel (P2 flies a racer) is worth
   keeping — same screen? alternating heats?
5. Session shape: ten heats to victory? endless mode after credits?
6. Passes: hard shield-hit only, or a grace mechanic (shoot the missile
   itself in flight)?
7. Name of the trench and the pod. "The Groove" is a placeholder.
8. Engine/tech: FutureBasic again, or SpriteKit via FB's SKView, or
   something else. Deferred until gameplay is settled.
