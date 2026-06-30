# Dave's Devilish Descent

A 2D troll-platformer built in **Godot 4.x / GDScript**. This repo is the
**playable game core** — the foundation that the larger design (many worlds,
backend, leaderboards, cosmetics) is meant to grow on top of.

It is **100% code-driven**: tiles, art, collision, levels, UI, and input are all
generated in GDScript, so there are no binary assets to break and the project
opens cleanly on any machine.

---

## What works right now

- **Tight movement** — run, variable-height jump, **double jump**, **wall slide
  / wall jump**, and an **8-directional dash**, with **coyote time** and **jump
  buffering** so the controls feel forgiving.
- **Instant respawn** with checkpoints; deaths and run timer tracked.
- **TileMap world** built from ASCII level grids (collision generated in code).
- **Pickups** — coins, a secret star per level — plus **spikes** and a
  **crumbling platform** as a first taste of the "troll" trap mechanics.
- **Smooth-follow camera** with screen shake; squash-&-stretch on the player.
- **HUD** (coins / deaths / timer / level) and on-screen toasts.
- **Progressive unlocks**: 1-1 teaches jumping, 1-2 grants double jump, 1-3
  grants dash.
- **Local save** of best times + totals to `user://save.json`.

## Controls

| Action   | Keyboard                | Gamepad |
|----------|-------------------------|---------|
| Move     | Arrow keys / `WASD`     | D-pad / left stick |
| Jump     | `Space` / `Z` / `K`     | A |
| Dash     | `Shift` / `X` / `L`     | X |
| Interact | `E` / `Enter`           | Y |
| Restart  | `R`                     | Back |
| Quit     | `Esc`                   | Start |

Input is registered at runtime in `src/autoload/game.gd` (`_setup_input`), so
remapping is a one-line change and there are no fragile bindings in
`project.godot`.

---

## Running it

You need the **Godot 4.3+** editor (it uses the `TileMapLayer` node). No export
templates are required just to play in the editor.

### Install Godot on macOS

**Option A — Homebrew (recommended):**
```bash
brew install --cask godot
```

**Option B — Direct download:** grab "Godot Engine 4.x (Standard)" for macOS
from <https://godotengine.org/download/macos/>, unzip, and move `Godot.app` to
`/Applications`. (Use the **Standard**, not the **.NET/C#**, build.)

### Open & play
1. Launch Godot → **Import**.
2. Select `project.godot` in this folder → **Import & Edit**.
3. Press **F5** (Run Project), or the ▶ button at the top right.

From a terminal you can also do:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path "$(pwd)"
```

---

## Project layout

```
project.godot          # config, display, autoload, render settings
main.tscn / main.gd    # entry point → Game.start()
src/
  autoload/game.gd     # singleton: state, level flow, input, save/load
  world/
    levels.gd          # the levels, as ASCII grids
    level.gd           # parses a grid → tilemap + entities + player + camera
    tile_factory.gd    # builds the solid TileSet (texture + collision) in code
  player/
    player.gd          # the controller (movement is all here)
    player_skin.gd     # drawing + squash/stretch
  camera/game_camera.gd
  entities/            # coin, star, spike, checkpoint, exit, crumble
  ui/hud.gd
```

### Adding / editing levels

Edit `src/world/levels.gd`. Each level is an array of equal-ish-length strings.

```
#  solid tile      P  player spawn    E  exit door
C  coin            S  secret star     ^  spikes (hazard)
K  checkpoint      X  crumbling platform     (space) = empty
```

Add `"unlock": "double"` or `"unlock": "dash"` to a level dict to grant an
ability when it's first reached. Tweak feel via the `const`s at the top of
`player.gd`.

---

## Roadmap — mapping to the full design

This core is phase 1. Suggested order for the rest:

1. **Trap framework** — generalize `crumble.gd` into a data-driven trap system
   (fake spikes, falling floors, fake exits, gravity flip, disappearing/invisible
   platforms, reverse controls). This is the game's identity.
2. **Content tooling** — move levels from ASCII to the Godot TileMap editor +
   a packed-scene-per-level workflow; build the world/level select.
3. **Enemies & bosses**, then the 6 worlds.
4. **Polish** — particles (dust/landing), audio (music + SFX), lighting,
   transitions, settings/accessibility menu.
5. **Meta** — cosmetics, achievements, speedrun ghosts, daily challenges.
6. **Backend** (Laravel REST): auth, cloud save, leaderboards, analytics,
   admin dashboard — add a thin `Api` autoload client in the Godot project.
7. **Export** — add `export_presets.cfg` and platform templates for
   Windows/Linux/macOS/Android/iOS/HTML5.

> Scope note: the original brief describes a multi-month, team-sized project
> (hundreds of levels, multiplayer, backend, admin tools). What's here is a
> solid, genuinely playable starting point you can build all of that onto — not
> the finished product.
