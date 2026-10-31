# Generational

A game about a family promise passed through the centuries.

The Eclipse Cult has stolen the Braunerkopf family's 'flame' (which grants fire-based abilities). Sir Reiner sets out to reclaim it, passing the duty to protect it to his descendants. As the cult grows to an institution, to a corporation, and even a robotic army, each new generation must bring the flame home. This is just discount Jojo's Bizarre Adventure.

## Play

Open `project.godot` in **Godot 4.7** and press **F5**. The game starts fullscreen; press **F11** to toggle windowed mode.

Choose a starting level at the bottom of the main menu using Left/Right arrows, the D-pad, or the left stick. Confirm to read that character's story and begin.

## Controls

| Action | Keyboard | Xbox | PlayStation | Nintendo |
|---|---|---|---|---|
| Move | Arrow keys | Left stick / D-pad | Left stick / D-pad | Left stick / D-pad |
| Attack | X | X | Square | Y |
| Confirm | Enter / Space | A | Cross | B |
| Pause / resume | Esc | Menu | Options | Plus |

Hold attack to repeat. Moving diagonally also aims attacks diagonally. Prompts update for the keyboard or controller you're using. Other mapped controllers use the bottom face button to confirm and the left face button to attack.

## How to play

Clear four enemy waves and defeat the boss in each era. The clock limits the ordinary waves and stops when the boss arrives. Collect power-ups for healing, multidirectional attacks, white fireballs, stronger attacks, or temporary invincibility.

You start with **three hearts in levels 1–3** and **four in level 4**. Healing cannot exceed that level's starting health. Enemy contact and fireballs cost a heart; running out of time costs all remaining hearts. Most fireballs can be broken with an attack.

After Game Over, choose **Retry Level** or **Start Over**. Defeating the final boss completes the story.

## Development

Project folders:

- `assets/sprites/`: characters, effects, environment, and interface artwork.
- `assets/audio/`: music and sound effects.
- `scenes/`: main scene and reusable actor scenes.
- `scripts/`, `shaders/`, and `resources/`: game logic, rendering, and level settings.
- `docs/` and `tests/`: architecture notes and development checks.

Level stories and settings live in `resources/level_*.tres`. Player and enemy behaviors are split into child-node scripts in `scripts/`.

Run automated checks with Python 3 and a Godot executable:

```sh
python3 tests/run_tests.py --godot /path/to/godot
```

See [the architecture guide](docs/ARCHITECTURE.md) for code structure and [credits](CREDITS.md) for asset and attribution notes.

## License

Source code is available under the [MIT License](LICENSE). Artwork, music, sound effects, story text, and other creative assets are **not** covered by that license. See [credits](CREDITS.md) for details.

## Credits

Music and art by me (Geethan). Sounds from https://ci.itch.io/400-sounds-pack.
