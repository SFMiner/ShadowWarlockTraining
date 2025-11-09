### Task 2.5a: Player Avatar Core Properties and Structure

**Dependencies**: Task 2.1  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:

1. Review existing `/mnt/project/player_avatar.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/player/player_avatar.gd` extending CharacterBody2D
3. Add core properties:
	- `current_position: Vector2i` - Tile coordinates
	- `current_direction: Vector2 = Vector2.RIGHT` - Facing direction
	- `is_transforming: bool = false` - Animation lock
	- `health: int = 1` - Always 1 (one-hit reset)
	- `transformation_history: Array[TransformationBase] = []` - For undo
	- `selected_ability: String = "shadow_slide"` - Currently selected transformation
4. Add signals:
	- `signal transformation_started(type: String)`
	- `signal transformation_complete(type: String)`
	- `signal transformation_cancelled()`
	- `signal player_hit()`
5. Implement `_ready()` function:
	- Initialize `current_position` from `global_position` using `GameConstants.pixel_to_tile()`
	- Snap player to tile center using `GameConstants.tile_to_pixel()`
6. Implement helper functions:
	- `update_sprite_direction() -> void` - Stub function (just `pass` for now)
	- `move_to_tile(tile_pos: Vector2i) -> void` - Updates both `current_position` and `global_position`
	- `get_tile_position() -> Vector2i` - Returns `current_position`
7. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:

- [ ]  Script compiles without errors
- [ ]  Player spawns at correct position
- [ ]  `current_position` matches tile coordinates
- [ ]  Player snaps to tile centers on spawn
- [ ]  Signals are defined

---

### Task 2.5b: Basic Input Handling for Player

**Dependencies**: Task 2.5a  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:

1. Update `res://scripts/player/player_avatar.gd` to add input handling
2. Implement `_input()` function for keyboard shortcuts:
	- Check if `TurnManager.current_phase != TurnManager.Phase.PLAYER_ACTION` → return early
	- Listen for InputEventKey with `event.pressed`
	- KEY_1 → set `selected_ability = "shadow_slide"`
	- KEY_2 → set `selected_ability = "mirrorwalk"`
	- KEY_3 → set `selected_ability = "pivot"`
	- KEY_4 → set `selected_ability = "shadowshift"`
3. Implement `_unhandled_input()` function for mouse clicks:
	- Check if `TurnManager.current_phase != TurnManager.Phase.PLAYER_ACTION` → return early
	- Listen for InputEventMouseButton (left button, pressed)
	- Get world position: `get_global_mouse_position()`
	- Convert to tile position: `GameConstants.pixel_to_tile(world_pos)`
	- Call `_start_transformation_targeting(tile_pos)`
4. Implement stub `_start_transformation_targeting()` function:
	- Parameter: `target_tile: Vector2i`
	- Print clicked tile position
	- Print current player tile position
	- Print selected ability
	- This is just for testing - will be expanded in Task 2.5c
5. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:

- [ ]  Script compiles without errors
- [ ]  Keyboard 1-4 keys change selected ability (check with print/debug)
- [ ]  Mouse clicks are detected (check console output)
- [ ]  Input only works during PLAYER_ACTION phase
- [ ]  Clicking tiles prints correct tile coordinates
- [ ]  Can manually test by setting TurnManager phase in debugger

---

### Task 2.5c: Transformation Execution Flow

**Dependencies**: Task 2.5b, Task 2.4, Task 3.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:

1. Update `res://scripts/player/player_avatar.gd` to implement transformation execution
2. Expand the `_start_transformation_targeting()` function:
	- Calculate direction vector from `current_position` to `target_tile`
	- Calculate distance as integer length
	- For now, only implement Shadow Slide execution
	- For other abilities, print "not yet implemented"
	- Call `_execute_shadow_slide(direction, distance)` for Shadow Slide
3. Implement `_execute_shadow_slide(direction: Vector2, distance: int)` function:
	- Create new Shadow Slide transformation instance
	- Set `target = self`
	- Set `parameters` dictionary with direction and distance
	- Call `TransformationValidator.validate(shadow_slide)`
	- If invalid: print reason and return
	- If valid: continue execution
	- Emit `transformation_started` signal
	- Call `shadow_slide._execute()`
	- Update `current_position` from new `global_position`
	- Add transformation to `transformation_history`
	- Emit `transformation_complete` signal
	- Call `TurnManager.end_player_action()` to advance turn
4. Add temporary debug helper in `_process()`:
	- If spacebar pressed (`ui_accept` action)
	- Force `TurnManager.current_phase = Phase.PLAYER_ACTION`
	- This allows testing without full turn system
	- Comment that this is DEBUG only and will be removed
5. Optionally show preview via PreviewSystem if available:
	- Check `if PreviewSystem:`
	- Call `PreviewSystem.create_ghost(self)` before execution
6. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:

- [ ]  Script compiles without errors
- [ ]  Clicking a tile attempts Shadow Slide to that tile
- [ ]  Validation messages appear if move is invalid (e.g., through wall)
- [ ]  Player actually moves to target tile when valid
- [ ]  Transformation signals emit correctly
- [ ]  Can test by pressing spacebar to force player action phase
- [ ]  Console shows transformation execution steps
- [ ]  Turn advances after transformation completes
