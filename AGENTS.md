# Agent notes for Devastator 2

Sequel to the Devastator port (../devastator, published at
github.com/wells01440/devastator). Design is settled and lives in
DESIGN.md — that file is the spec; do not re-litigate settled decisions,
raise conflicts with the owner instead.

## State

Skeleton only. The app builds and opens a window with a placeholder
scene. No gameplay exists yet.

## Layout

| Path | Holds |
|---|---|
| DESIGN.md | the gameplay spec, settled through four design rounds |
| Package.swift | SPM executable target, macOS 13+ |
| Sources/Devastator2/main.swift | AppKit bootstrap: window + SKView |
| Sources/Devastator2/GameScene.swift | the scene; placeholder |
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

## Next milestone: the grey-box

Purpose: answer whether aim-as-movement feels good. Nothing ships from
it. Scope, in order:

1. The U trench in grey boxes: a horizontal band for the sky, a U
   profile for the track, drawn flat (pseudo-3D row scaling comes
   later).
2. Crosshair moved by arrows; pod chases the crosshair's horizontal
   position along the U with Tuning.aimFollowLag; gravity eases both
   toward center at Tuning.gravityRecenterPerSecond when idle.
3. One Skimmer: enters at the far end, races toward the near end,
   gentle weave, tries to pass.
4. The 10-second pass clock as a shrinking ring on the Skimmer.
5. Space fires; a hit needs the crosshair on the Skimmer; kill resets
   the spawn.
6. One fixed obstacle in the trench that the pod bumps against.

Rules for the milestone: every constant goes in Tuning.swift; keep the
scene tree flat and disposable; no music, no art, no score display
beyond a debug line. When it runs, the owner plays it and the feel
conversation starts — expect Tuning values to churn.

## Conventions

- Swift, SpriteKit, AVAudioEngine, GameController. Platform-native
  only; no third-party packages without the owner's say.
- No magic numbers outside Tuning.swift.
- Music: read Assets/Music/MANIFEST.md before touching audio. Slot
  assignments there are provisional until the owner's ear pass. Never
  edit the MP3s in place; masters live in the bugthing project.
- Owner's global style rules apply to all text (terse, factual, no
  concessive compounds, no em dashes).
