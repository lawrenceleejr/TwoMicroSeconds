# two microseconds

[![build-macos](https://github.com/lawrenceleejr/TwoMicroSeconds/actions/workflows/build-macos.yml/badge.svg)](https://github.com/lawrenceleejr/TwoMicroSeconds/actions/workflows/build-macos.yml)

*the (brief) life of a muon* — a cute little game in the spirit of Untitled Goose Game,
except the goose is a subatomic particle and the pond is the entire atmosphere.

You are a muon, freshly minted by a cosmic ray high above a particle detector.
Your mean proper lifetime is **2.2 µs**, decay is genuinely random, and the
game plays out in **your own rest frame**: energy can never stretch your
clock — what it does is **length-contract the atmosphere**, so a hotter birth
makes the ground arrive sooner while Earth's lab clock races ahead of yours.
You can't throttle (only electric fields accelerate a charged particle; the
fields that steer you do no work). Reach the Muon Observatory before the dice
come up decay. Every death is logged: a persistent histogram of proper
lifetimes converges on 2.2 µs as you play, with the γ-stretched lab-frame
distribution underneath.

## how to play

| input | action |
|---|---|
| WASD / arrows / left stick | **steer** (that's all the control you get) |
| SPACE / Z / X / click (gamepad A/X) | **zap** — your honk; everything reacts |
| TAB | to-do list |
| U | origin shop (title screen) |
| ESC | pause |
| R | restart (on the end screen) |
| F / M | fullscreen / mute |

**You cannot throttle a muon.** Nothing accelerates a charged particle but an
electric field: the atmosphere constantly bleeds your speed away (ionization
drag), and you get it back by surfing **auroral electrojets**, triggering
**thundercloud fields** (zap a cloud), or bumping **satellites**. Speed is
your clock — and the view tells you so, *A Slower Speed of Light*-style:
the world **length-contracts** along your direction of motion, **Doppler
shifts** (blue ahead, red behind, with a headlight brightening), and motion
blur creeps in as γ climbs.

The to-do list is optional, goose-style: tickle an aurora, high-five a
satellite, photobomb a shooting star, startle a weather balloon, zip through
an airplane, make a cloud rain… Finish all ten before being detected and
the observatory stamps your receipt **A++ MUON**. Fresh solar-flare muons cannot reach the ground — early runs
are for sparks; come back heavier.

## sparks & the origin shop

Drowsy **satellites** drift through the thermosphere. Bump one and its flight
computer reboots — the screen glitches out for half a second, you pocket a
**spark**, and its capacitors hurl you downward (hit it fast for a bigger
kick). Every man-made thing you clip — balloons, airplanes — glitches the
same way. Finishing a run pays +3 sparks; a perfect mischief sheet +5 more.

Sparks persist between runs and are spent in the **origin shop** (press U on
the title screen) on better cosmic-ray production mechanisms. Each tier means
more energy at birth, i.e. a permanently higher Lorentz factor:

solar flare → red dwarf superflare → supernova shock front (Fermi
acceleration) → pulsar wind nebula → magnetar flare → active galactic
nucleus → **the Oh-My-God particle** (Utah, 1991, 3×10²⁰ eV) — a golden
muon whose detection earns the game's final ending.

## play in the browser

Every push deploys a web build to GitHub Pages:

**https://lawrenceleejr.github.io/TwoMicroSeconds/**

(Single-threaded WASM via Godot's web export — audio may crackle slightly
compared to the native build; save data lives in your browser's storage.)

## download (macOS)

Every push to `main` builds a DMG on GitHub Actions:

1. Grab the **TwoMicroseconds-macOS** artifact from the latest
   [build-macos run](https://github.com/lawrenceleejr/TwoMicroSeconds/actions/workflows/build-macos.yml).
2. Unzip it, open `TwoMicroseconds-macOS.dmg`, and drag the app onto the
   bundled **Applications** link.
3. Read **RUN ME FIRST.txt** inside the DMG — the app is ad-hoc signed (no
   Apple Developer ID), so Gatekeeper needs one nudge. The short version:

   ```sh
   xattr -cr "/Applications/Two Microseconds.app"
   open "/Applications/Two Microseconds.app"
   ```

   or run the raw binary directly:

   ```sh
   "/Applications/Two Microseconds.app/Contents/MacOS/Two Microseconds"
   ```

## the physics (yes, really)

Cosmic-ray muons are created ~15 km up and live 2.2 µs in their own frame.
Classically they'd travel ~660 m before decaying; relativistically, time
dilation (γ = 1/√(1−v²/c²)) stretches their laboratory lifetime enough to
reach the ground in droves — about one per cm² per minute reaches sea level.
Muons arriving at your detector are one of the classic demonstrations of
special relativity — and in the muon's own frame the resolution is length
contraction, which is exactly the mechanic here. The decay products are an
electron, a muon neutrino, and an electron antineutrino; the birth chain
(proton -> pion -> muon + neutrino) is the real one too. The game still takes
liberties (an atmosphere five screens tall, clouds with faces, a scenic
start at 100 km because the aurora was too pretty to skip).

## the soundtrack (and how to replace it)

The game generates a cute 8-bar loop at startup (C–Am–F–G, plucks + pad +
bass, 104 BPM). To swap in your own music, drop `track.ogg` into `music/`
(ships with the build) or `music.ogg` into the game's user-data folder
(works on the shipped app, no rebuild). Details in
[`music/README.md`](music/README.md).

## building locally

Everything in this repo is text: all art is drawn in code, all audio is
synthesized at startup. No binary assets, no imports to fight.

- Install [Godot 4.4.1-stable](https://godotengine.org/download) and open the
  project, or run it headless-imported from the CLI:

  ```sh
  godot --headless --import   # first time, builds the .godot cache
  godot                       # play
  ```

- The macOS export runs in CI (`.github/workflows/build-macos.yml`):
  headless import → `--export-release "macOS"` → ad-hoc `codesign` →
  headless smoke test → `hdiutil` DMG. To reproduce the export locally you
  need the matching 4.4.1 export templates.

## project layout

```
game/
  autoload/   juice.gd (shake/hitstop/palette) · sfx.gd (synth audio)
              tasks.gd (the to-do list) · game.gd (flow + input map)
  player/     muon.gd + body/face (movement, dash, zap, squash & stretch)
  world/      atmos.gd (constants) · atmosphere.gd (sky) · layer_director.gd
              props/ (auroras, balloons, clouds, birds, airplane, detector…)
  ui/         hud.gd · checklist.gd · end_screen.gd · pause_overlay.gd
  fx/         zap_ring · ghost · decay_burst · task_pop · float_text · intro
dist/         RUN_ME_FIRST.txt (ships inside the DMG)
```
