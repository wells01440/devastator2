# Music manifest

Twelve tracks curated from the owner's chiptune/demoscene library in
../../../bugthing/art-department/music (owner-composed, owner-owned; see
that folder's README for the full 40-track catalog). Filenames are kept
from the source so the two libraries stay traceable — the names are bug
themed and mean nothing here; this table is the meaning.

Slot assignments are by length and energy read from the source notes,
not by ear. The ear pass is the owner's. MP3s are unmodified; edit
masters live in the source folder. Loudness normalization, seamless loop
points, and any stem splits for the adaptive-layer design happen at
integration time, never in place here.

| File | Length | Proposed slot | Note |
|---|---|---|---|
| intro-screen.mp3 | 3:24 | title screen | the big open |
| vector-horizon.mp3 | 1:16 | level theme | the name is already this game |
| plastic-machete-remastered.mp3 | 3:19 | level theme | demoscene cut |
| centipede-dubstep.mp3 | 2:04 | level theme | harder gear |
| bug-battle.mp3 | 0:44 | gameplay loop candidate | short, loopable |
| bug-battle-long-difficult.mp3 | 1:29 | late-level theme | faster |
| hornet-chiptune-dubstep.mp3 | 2:31 | pace pod (mini-boss) | aggressive |
| unber-battle.mp3 | 4:31 | final level / the Devastator | the long one |
| pre-battle-fly-by-1.mp3 | 2:26 | intro cut scene / level interstitial | build-up energy |
| post-bug-battle-victory.mp3 | 1:17 | victory screen | |
| wicked-wasp-scene-1.mp3 | 0:51 | kill-shot cut scene | short, dark |
| suikinkutsu2.mp3 | 3:11 | credits / defeat quiet | water chime, the calm outlier |

Ten level themes are needed and five candidates exist; levels can share
themes across palette shifts, or more tracks can be pulled from the
source catalog after the ear pass.

Not yet bundled into the build: the grey-box is silent. When music
lands, add the files as SPM resources and play through AVAudioEngine
(layering design is in DESIGN.md, Sound section).
