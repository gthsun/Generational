# Game architecture

Open `scenes/main.tscn` in Godot to inspect the scene tree. The controller coordinates level state and update order; it does not own actor movement, attack, health, projectile or UI state.

```text
Eclipse                         scripts/game.gd
├── Assets                      scripts/game_assets.gd
├── World
│   ├── Arena                   scripts/arena.gd
│   ├── Powerups                scripts/powerups.gd
│   ├── Actors                  Godot Y-sorted actor container
│   │   ├── Enemies             scripts/enemy_manager.gd
│   │   │   └── Enemy instances scenes/enemy.tscn
│   │   │       ├── Movement    scripts/enemy_movement.gd
│   │   │       ├── Weapon      scripts/enemy_weapon.gd
│   │   │       │   └── SpecialAttack scripts/boss_special_attack.gd
│   │   │       ├── PhaseTransition   scripts/enemy_phase.gd
│   │   │       ├── Maneuver    scripts/boss_maneuver.gd
│   │   │       ├── FinalPhase  scripts/boss_final_phase.gd
│   │   │       ├── Footsteps   scripts/footsteps.gd
│   │   │       └── Visual      scripts/enemy_visual.gd
│   │   └── Player              scenes/player.tscn; scripts/player.gd
│   │       ├── Movement        scripts/player_movement.gd
│   │       ├── Health          scripts/player_health.gd
│   │       ├── Footsteps        scripts/footsteps.gd
│   │       └── Melee           scripts/player_melee.gd
│   ├── PlayerEffects           scripts/player_effects.gd
│   └── Projectiles             scenes/projectiles.tscn; scripts/projectiles.gd
│       ├── Normal              scripts/projectile_visual.gd
│       ├── Blue                same renderer, blue shader
│       ├── Special             same renderer, custom-color shader
│       └── Friendly            same renderer, white shader
├── HUD                         scripts/hud.gd
├── Music                       scripts/music.gd
├── SoundEffects                scripts/sound_effects.gd
├── BossVictoryAudio            scripts/boss_victory_audio.gd
└── InputControls               scripts/input_controls.gd
```

## Ownership and communication

- The player owns its transform and visual representation. Its Movement, Health and Melee children own their corresponding state. Changing movement does not require editing weapon or health logic.
- Each enemy is a real scene instance with its own behavior children, rather than an entry whose behavior lives in the controller. Enemy identity and health live on the actor; its behavior timers live on the appropriate children.
- `Health.died` informs the controller of player death. An enemy's `defeated` signal lets the spawner remove it and emit `enemy_defeated` for scoring. `PhaseTransition.transition_started` cancels the weapon's current firing sequence before a jump.
- The `enemies` group provides actor discovery. The spawner filters it by parent, so multiple game instances in tests cannot affect each other. The `players` group identifies player actors. The `game_views` group refreshes only views belonging to the current controller.
- `setup` explicitly injects the actor/controller context. Components use sibling APIs through those references for synchronous combat queries. Signals handle lifecycle events; they are not used to obscure order-sensitive collision checks.
- Projectiles are intentionally simulated as a batch of records within their own system, with separate rendering nodes. This keeps the 50-shot salvo inexpensive. The controller only asks the system to advance; movement, homing, parrying and collisions are separate small functions in that system.
- `game_component.gd` shares only setup and drawing primitives. `actor_component.gd` shares only dependency setup. Neither contains gameplay or forwards unknown properties.

## Resources and tuning

`resources/level_1.tres` through `level_4.tres` use the custom `LevelDefinition` resource (`scripts/level_definition.gd`). Edit these in the Inspector to change the year, story, time limit, attack duration/cooldown, grass tint, enemy health, boss health and sizes, enemy speed bonus, health by wave, shooter limits, retreat speed, recovery times and special-attack warnings/speeds. The resource is configuration; runtime state never writes to it.

`game_rules.gd` contains shared constants and pure direction/frame-selection functions. `game_assets.gd` loads the existing sprite textures once per game and shares them with the rendering components.

## Update order and rendering

The controller advances systems in their original order: power clocks, deadline, player timers/movement, pickups, melee input (which signals powered shooting), enemy AI, melee hits, contact damage, projectile collisions, then corpses. Only the playing state advances combat; pause and transition cards freeze it. This preserves attack/parry timing and timeout semantics.

Godot's Y-sort handles actor depth. Effects and projectile layers follow actors; HUD draws last. Views request redraw through their own nodes, so drawing no longer depends on one large `_draw()` function.

## Validation

Run `python3 tests/run_tests.py --godot /path/to/godot` from the project folder. The runner checks every active `*test.gd` fixture and writes logs to ignored `test-results/`. It fails on nonzero exit codes, timeouts, missing completion markers, or Godot errors, including assertion failures that Godot sometimes reports with exit code zero.

The tests cover scene lifecycle, scoped groups, combat, bosses, health caps, progression, audio, controller input and menu navigation. Controller events are simulated; physical hardware still needs testing. Visual fixtures can be run separately in a graphical Godot session, for example `godot --path . --script tests/ending_visual.gd --max-fps 60`.

Old B/W shortcut fixtures are archived locally under ignored `tests/archive/`. Generated screenshots and reports are also ignored. Active tests verify those shortcuts remain disabled. `.uid` files and asset `.import` configuration should remain versioned; `.godot/` is generated locally.
