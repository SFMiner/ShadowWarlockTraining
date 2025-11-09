# Shadow Warlock Training - Claude Code Task List
## For Claude Sonnet Haiku 4.5 Execution

**Project**: Shadow Warlock Training - Educational Tactical Puzzle Game  
**Engine**: Godot 4.5  
**Language**: GDScript (tabs for indentation)  
**Platform**: HTML5 Browser Deployment  

**Note**: All tasks defer to Implementation Plan and GDD documentation. Existing code files in /mnt/project are initial suggestions only and may conflict with current specifications.

---

## PHASE 1: Foundation & Architecture
**Goal**: Establish project structure, core systems, and data architecture

### Task 1.1: Project Setup and Configuration
**Dependencies**: None  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create new Godot 4.5 project named "ShadowWarlockTraining"
2. Set project settings:
	- Display/window/size/viewport_width = 640
	- Display/window/size/viewport_height = 480
	- Display/window/stretch/mode = "viewport"
	- Display/window/stretch/aspect = "keep"
	- Rendering/textures/canvas_textures/default_texture_filter = "Nearest" (pixel-perfect)
	- Physics/2d/physics_engine = "GodotPhysics2D"
	- Physics/2d/default_gravity = 0 (no gravity - top-down)
	- Physics/common/physics_ticks_per_second = 30
3. Create complete folder structure:
	```
	res://
	├── scenes/
	│   ├── main/
	│   ├── player/
	│   ├── enemies/
	│   ├── levels/
	│   │   ├── training/
	│   │   ├── tactical/
	│   │   └── boss/
	│   ├── ui/
	│   └── effects/
	├── scripts/
	│   ├── autoload/
	│   ├── player/
	│   ├── enemies/
	│   ├── systems/
	│   ├── transformations/
	│   ├── ui/
	│   └── levels/
	├── assets/
	│   ├── sprites/
	│   │   ├── characters/
	│   │   ├── enemies/
	│   │   ├── tiles/
	│   │   └── ui/
	│   ├── audio/
	│   │   ├── music/
	│   │   └── sfx/
	│   └── fonts/
	└── data/
		├── levels/
		└── balance/
	```
4. Configure HTML5 export preset:
	- Name: "Web"
	- Export path: "builds/web/index.html"
	- Custom HTML shell: Use default
	- Head include: (empty for now)

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Project opens without errors
- [ ] All folders exist in correct hierarchy
- [ ] Project settings applied correctly (check viewport size, pixel-perfect rendering)
- [ ] HTML5 export preset configured

---

### Task 1.2: Enhanced GameConstants Autoload
**Dependencies**: Task 1.1  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Review existing `res://game_constants.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/autoload/game_constants.gd` based on GDD specifications:
	- Tile size: 16 pixels
	- Base range: 1 tile
	- Range per level: 1 tile per level
	- Target type power costs (SELF: 100%, OBJECT: 150%, ENEMY: 200%)
	- Level cap: 10
	- XP to reach level 10: 900 XP
	- All transformation parameters per GDD Section 10.3
3. Add helper functions:
	- `get_transformation_range(player_level: int, ability: String) -> int`
	- `get_effective_level_for_target(player_level: int, target_type: TargetType) -> int`
	- `tile_to_pixel(tile_coord: Vector2i) -> Vector2`
	- `pixel_to_tile(pixel_pos: Vector2) -> Vector2i`
4. Use tabs for indentation (NOT spaces)
5. Add comprehensive comments explaining each constant's purpose
6. Configure as AutoLoad singleton in Project Settings:
	- Path: `res://scripts/autoload/game_constants.gd`
	- Name: `GameConstants`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors (F6 to test)
- [ ] AutoLoad configured correctly (shows in Project > Project Settings > Autoload)
- [ ] Constants match GDD specifications (tile size = 16, level cap = 10, XP = 900)
- [ ] Helper functions return correct values when tested

---

### Task 1.3: Enhanced GameManager Autoload
**Dependencies**: Task 1.2  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Review existing `res://game_manager.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/autoload/game_manager.gd` implementing:
	- Player progression tracking (level, XP)
	- Ability unlock system per GDD level progression
	- Multi-target system (Split Power at level 3, Mastery at level 5)
	- Combination system (2-combo at level 4, 3-combo at level 7, 4-combo at level 8)
	- Level completion tracking
	- Bestiary unlock system
	- Settings (volume_master, volume_music, volume_sfx, grid_overlay, angle_snap)
3. Implement signals:
	- `level_up(new_level: int)`
	- `xp_gained(amount: int)`
	- `ability_unlocked(ability_name: String)`
	- `level_completed(level_num: int)`
4. Implement ability unlock progression per GDD:
	- Level 1: shadow_slide, mirrorwalk, turn (always available)
	- Level 2: shadowshift_self, split_max_targets = 2
	- Level 3: shadow_pivot, split_power
	- Level 4: shadowshift_object, combo_2
	- Level 5: multi_target_mastery, mastery_max_targets = 2
	- Level 6: shadowshift_enemy
	- Level 7: combo_3, mastery_max_targets = 3
	- Level 8: combo_4
	- Level 9: mastery_max_targets = 4
	- Level 10: mastery_max_targets = 99
5. Leave save/load functions as stubs (will implement in Task 1.5)
6. Use tabs for indentation
7. Configure as AutoLoad singleton:
	- Path: `res://scripts/autoload/game_manager.gd`
	- Name: `GameManager`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured correctly
- [ ] Ability unlock logic matches GDD progression
- [ ] Signals defined correctly
- [ ] Test `gain_xp()` and `check_level_up()` functions work

---

### Task 1.4: SaveSystem Autoload with localStorage
**Dependencies**: Task 1.3  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/autoload/save_system.gd`
2. Implement browser localStorage integration using JavaScriptBridge:
	```gdscript
	var js_interface = null
	
	func _ready() -> void:
		if OS.has_feature("web"):
			js_interface = JavaScriptBridge.get_interface("localStorage")
	```
3. Implement save format per GDD Section 10.4:
	- Version: "1.0"
	- Timestamp
	- Player data (level, XP)
	- Abilities dictionary
	- Ranges dictionary
	- Multi-target settings
	- Progress (levels_complete, current_level, resets_used)
	- Bestiary unlocks
	- Settings
4. Implement functions:
	- `save_game(data: Dictionary) -> bool` - Returns success/failure
	- `load_game() -> Dictionary` - Returns save data or empty dict
	- `delete_save() -> void`
	- `has_save() -> bool`
5. Handle localStorage errors gracefully:
	- Check if localStorage available
	- Handle quota exceeded errors
	- Handle corrupt data (JSON parse errors)
	- Provide fallback empty data
6. Implement save versioning for future updates
7. Use tabs for indentation
8. Configure as AutoLoad singleton:
	- Path: `res://scripts/autoload/save_system.gd`
	- Name: `SaveSystem`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured correctly
- [ ] Test `save_game()` creates localStorage entry (use browser console F12)
- [ ] Test `load_game()` retrieves saved data
- [ ] Error handling works (test with storage disabled if possible)
- [ ] Save format matches GDD specification

---

### Task 1.5: Connect GameManager to SaveSystem
**Dependencies**: Task 1.4  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Update `res://scripts/autoload/game_manager.gd`:
2. Implement `save_game()` function:
	- Collect all state into Dictionary
	- Call `SaveSystem.save_game(data)`
	- Emit signal if needed
3. Implement `load_game()` function:
	- Call `SaveSystem.load_game()`
	- Apply loaded data to all variables
	- Trigger `update_ranges()`
	- Handle missing data gracefully (new save)
4. Call `load_game()` in `_ready()`
5. Auto-save on:
	- Level completion
	- Ability unlock
	- Settings change
6. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] `save_game()` and `load_game()` functions work
- [ ] Test save/load cycle preserves all data
- [ ] Auto-save triggers work (complete a level, change setting)
- [ ] New game starts with correct defaults

---

### Task 1.6: LevelManager Autoload
**Dependencies**: Task 1.3  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create `res://scripts/autoload/level_manager.gd`
2. Implement level loading system:
	- `load_level(level_number: int) -> void`
	- `get_level_data(level_number: int) -> Dictionary`
	- `transition_to_level(level_number: int) -> void`
3. Create level data structure (stub for now, full implementation in Phase 6):
	```gdscript
	var level_data: Dictionary = {
		1: {
			"name": "Shadow Slide Trial",
			"type": "training",
			"xp_reward": 100,
			"scene_path": "res://scenes/levels/training/level_01.tscn"
		},
		# ... etc
	}
	```
4. Implement scene transition with fade:
	- Fade out current scene
	- Load new scene
	- Fade in
5. Track current level
6. Implement level unlock logic:
	- `is_level_unlocked(level_number: int) -> bool`
	- Check GameManager.levels_complete
7. Add signals:
	- `level_loaded(level_number: int)`
	- `level_transition_started()`
	- `level_transition_complete()`
8. Use tabs for indentation
9. Configure as AutoLoad singleton:
	- Path: `res://scripts/autoload/level_manager.gd`
	- Name: `LevelManager`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured correctly
- [ ] Level data structure defined
- [ ] Transition functions implemented (test with dummy scenes if possible)
- [ ] Unlock logic works correctly

---

### Task 1.7: JSON Data Schema Design
**Dependencies**: Task 1.6  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://data/levels/level_schema_example.json` with complete schema:
	```json
	{
		"level_number": 1,
		"name": "Shadow Slide Trial",
		"type": "training",
		"duration_estimate_minutes": 10,
		"difficulty_stars": 1,
		"learning_objectives": ["Introduce translation"],
		"arena": {
			"width_tiles": 40,
			"height_tiles": 25,
			"tilemap_data": "res://data/levels/level_01_tilemap.tres"
		},
		"player_start": {
			"position": [20, 20],
			"direction": [1, 0]
		},
		"objectives": {
			"primary": "Reach the exit",
			"secondary": ["Use Shadow Slide 5 times"]
		},
		"enemies": [
			{
				"type": "hound",
				"position": [30, 15],
				"patrol_points": [[30, 15], [35, 15]]
			}
		],
		"hazards": [
			{
				"type": "spike_trap",
				"position": [25, 20]
			}
		],
		"tutorial_sequence": [
			{
				"step": 1,
				"text": "Welcome to Shadow Slide training...",
				"wait_for_input": true
			}
		],
		"xp_reward": 100,
		"unlocks_level": 2
	}
	```
2. Create `res://data/balance/difficulty_settings.json`:
	```json
	{
		"easy": {
			"enemy_telegraph": "sequential",
			"telegraph_indicators_persist": true,
			"turn_timer_seconds": 0,
			"show_ghost_previews": true
		},
		"normal": {
			"enemy_telegraph": "sequential",
			"telegraph_indicators_persist": false,
			"turn_timer_seconds": 0,
			"show_ghost_previews": false
		},
		"hard": {
			"enemy_telegraph": "simultaneous",
			"telegraph_indicators_persist": false,
			"turn_timer_seconds": 20,
			"show_ghost_previews": false
		}
	}
	```
3. Create `res://data/balance/enemy_config.json` with basic enemy stats
4. Create `res://data/balance/transformation_params.json` with transformation parameters
5. Document schema in `res://data/README.md`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] All JSON files are valid (use JSON validator or Godot's JSON parser)
- [ ] Schema matches GDD specifications
- [ ] Example level data is complete
- [ ] Difficulty settings match GDD Section 8
- [ ] README documents schema clearly

---

## PHASE 2: Core Movement & Validation
**Goal**: Implement grid system and transformation foundation

### Task 2.1: Grid System and TileMap Setup
**Dependencies**: Task 1.2  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create `res://scripts/systems/grid_system.gd`:
	- Tile size constant from GameConstants
	- `world_to_tile(world_pos: Vector2) -> Vector2i`
	- `tile_to_world(tile_pos: Vector2i) -> Vector2`
	- `is_tile_valid(tile_pos: Vector2i, grid_size: Vector2i) -> bool`
	- `get_tile_center(tile_pos: Vector2i) -> Vector2`
	- `get_tiles_in_range(center: Vector2i, range_tiles: int) -> Array[Vector2i]`
	- `get_manhattan_distance(from: Vector2i, to: Vector2i) -> int`
2. Create base TileSet resource `res://assets/tiles/base_tileset.tres`:
	- Define tile types: FLOOR, WALL, HAZARD, EXIT
	- Use 16x16 tile size
	- Set up collision shapes for WALL tiles
3. Create `res://scenes/levels/level_template.tscn`:
	- Root: Node2D
	- └── TileMap (using base_tileset.tres)
	- └── Entities (Node2D) - container for player/enemies
	- └── Markers (Node2D) - player start, exits, objectives
4. Create `res://scripts/levels/level_base.gd`:
	- Extend Node2D
	- Load level data from JSON
	- Setup TileMap from data
	- Spawn player and enemies
	- Implement boundary checking
5. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] GridSystem functions return correct values
- [ ] TileSet created with 16x16 tiles
- [ ] level_template.tscn opens without errors
- [ ] Test tile_to_world and world_to_tile conversions
- [ ] Boundary checking works correctly

---

### Task 2.2: Transformation Base Class
**Dependencies**: Task 2.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/transformations/transformation_base.gd`:
	- Abstract base class for all transformations
	- Implement Command pattern for undo/redo
	- Define virtual methods:
		- `_validate() -> bool` - Check if transformation is legal
		- `_execute() -> void` - Perform transformation
		- `_undo() -> void` - Reverse transformation
		- `_preview() -> void` - Show ghost preview
		- `_clear_preview() -> void` - Remove preview
	- Store transformation state:
		- `target: Node2D` - What to transform
		- `parameters: Dictionary` - Transformation-specific data
		- `original_state: Dictionary` - For undo
	- Implement power cost calculation:
		- Get target type (SELF/OBJECT/ENEMY)
		- Calculate effective level from GameConstants
		- Store power cost
	- Add signals:
		- `validation_failed(reason: String)`
		- `transformation_complete()`
2. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Virtual methods defined correctly
- [ ] Power cost calculation matches GDD
- [ ] Command pattern structure correct
- [ ] Signals defined

---

### Task 2.3: Transformation Validator System
**Dependencies**: Task 2.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/systems/transformation_validator.gd`:
2. Implement validation checks:
	- `validate_range(transformation: TransformationBase) -> bool`
		- Check target is within effective range
		- Use GameConstants.get_transformation_range()
	- `validate_target_type(transformation: TransformationBase) -> bool`
		- Check ability is unlocked for target type
		- Check GameManager.abilities
	- `validate_collision(transformation: TransformationBase) -> bool`
		- Check destination tile is valid
		- Check no obstacle collision (for Shadow Slide)
		- Allow Mirrorwalk to pass barriers
	- `validate_multi_target(targets: Array[Node2D]) -> bool`
		- Check count <= split_max_targets or mastery_max_targets
		- Check if Split Power or Mastery is unlocked
	- `validate_combo(transformations: Array[TransformationBase]) -> bool`
		- Check combo length <= unlocked combo limit
		- Check each transformation in combo is valid
3. Implement master validation function:
	- `validate(transformation: TransformationBase) -> Dictionary`
	- Returns: `{valid: bool, reason: String}`
4. Add visual feedback for invalid moves (red highlight)
5. Use tabs for indentation
6. Make singleton (AutoLoad):
	- Path: `res://scripts/systems/transformation_validator.gd`
	- Name: `TransformationValidator`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured
- [ ] Range validation works correctly
- [ ] Target type validation checks GameManager
- [ ] Collision validation differentiates Shadow Slide vs Mirrorwalk
- [ ] Multi-target validation matches GDD

---

### Task 2.4: Preview/Ghost System
**Dependencies**: Task 2.2  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create `res://scripts/systems/preview_system.gd`:
2. Implement ghost sprite creation:
	- `create_ghost(source: Node2D) -> Node2D`
	- Duplicate source sprite
	- Set modulate to semi-transparent (alpha 0.5)
	- Add to "Previews" layer
	- Return ghost node
3. Implement preview positioning:
	- `update_ghost_position(ghost: Node2D, target_pos: Vector2) -> void`
	- Smoothly interpolate to position
	- Add color coding:
		- Green: Valid transformation
		- Red: Invalid transformation
4. Implement preview clearing:
	- `clear_all_previews() -> void`
	- Remove all ghost nodes
5. Implement transformation trail preview:
	- For Shadow Slide: show dotted line path
	- For Mirrorwalk: show mirror axis line
	- For Pivot: show rotation arc
	- For Shadow Pivot: show tether line and arc
6. Use tabs for indentation
7. Make singleton (AutoLoad):
	- Path: `res://scripts/systems/preview_system.gd`
	- Name: `PreviewSystem`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured
- [ ] Ghost sprites create correctly
- [ ] Color coding works (green/red)
- [ ] Trail previews render correctly
- [ ] Previews clear properly

---

### Task 2.5: Enhanced Player Avatar Controller
**Dependencies**: Task 2.1, Task 2.4  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Review existing `res://player_avatar.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/player/player_avatar.gd` extending CharacterBody2D:
3. Implement core properties:
	- `current_position: Vector2i` - Tile coordinates
	- `current_direction: Vector2` - Facing direction (normalized)
	- `is_transforming: bool` - Animation lock
	- `health: int` - Always 1 (one-hit reset)
	- `transformation_history: Array[TransformationBase]` - For undo
4. Implement input handling:
	- Mouse click for transformation selection
	- UI wheel for ability selection (stub for now)
	- Keyboard shortcuts for abilities (1-4 keys)
5. Implement transformation execution flow:
	- `execute_transformation(transformation: TransformationBase) -> void`
	- Validate via TransformationValidator
	- Show preview via PreviewSystem
	- Wait for confirmation
	- Execute transformation
	- Add to history
	- Update position/direction
	- Emit signal to TurnManager
6. Implement sprite direction updates:
	- 8-directional sprite system
	- Update based on current_direction
7. Add signals:
	- `transformation_started(type: String)`
	- `transformation_complete(type: String)`
	- `transformation_cancelled()`
	- `player_hit()`
8. Implement smooth visual interpolation between tiles
9. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Player moves to tile centers correctly
- [ ] Input handling works
- [ ] Transformation flow is correct
- [ ] Sprite direction updates properly
- [ ] Signals emit correctly

---

### Task 2.6: Player Avatar Scene Setup
**Dependencies**: Task 2.5  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create `res://scenes/player/player_avatar.tscn`:
	- Root: CharacterBody2D (script: player_avatar.gd)
	- ├── Sprite2D (placeholder 16x16 colored square for now)
	- ├── CollisionShape2D (CircleShape2D, radius 6)
	- ├── Area2D - "HitDetection"
	- │   └── CollisionShape2D (slightly larger for hit detection)
	- └── AnimationPlayer (for transformation animations)
2. Set collision layers:
	- Player on layer 1
	- Collision mask: layers 2 (walls), 3 (enemies), 4 (hazards)
3. Configure Area2D signals:
	- Connect `area_entered` to detect enemy contact
	- Connect `body_entered` for hazard detection
4. Add placeholder sprite:
	- 16x16 colored square
	- Purple color (#9C27B0) per GDD
5. Set initial direction indicator (small arrow or dot)

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Scene opens without errors
- [ ] Collision shape visible in editor
- [ ] Area2D configured correctly
- [ ] Sprite displays correctly
- [ ] Can instantiate in test scene

---

## PHASE 3: The Four Shadow Arts
**Goal**: Implement all transformation abilities

### Task 3.1: Shadow Slide (Translation)
**Dependencies**: Task 2.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/transformations/shadow_slide.gd` extending TransformationBase
2. Implement parameters:
	- `direction: Vector2` - Movement direction (8 cardinal/ordinal)
	- `distance_tiles: int` - How far to move
3. Implement `_validate()`:
	- Check range using GameConstants
	- Check collision with barriers using raycasts
	- Check target within arena bounds
	- Return validation result
4. Implement `_execute()`:
	- Store original position
	- Calculate target position
	- Check each tile along path for barriers
	- If blocked, stop at last valid tile
	- Animate to target position
	- Update target's position
5. Implement `_undo()`:
	- Restore original position
6. Implement `_preview()`:
	- Show ghost at target position
	- Show dotted line path (purple color #9C27B0)
	- Highlight blocked tiles in red
7. Implement visual effects:
	- Shadow trail particles during movement
	- Purple glow at start and end
	- Smooth interpolation animation (0.3-0.5 seconds)
8. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Validation catches barriers correctly
- [ ] Execution moves to correct position
- [ ] Stops at barriers (doesn't teleport through)
- [ ] Preview shows path correctly
- [ ] Undo restores position
- [ ] Visual effects display (even if placeholders)
- [ ] Range scaling with level works

---

### Task 3.2: Mirrorwalk (Reflection)
**Dependencies**: Task 2.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/transformations/mirrorwalk.gd` extending TransformationBase
2. Implement parameters:
	- `mirror_start: Vector2` - Mirror line start point
	- `mirror_end: Vector2` - Mirror line end point
	- `target: Node2D` - What to reflect
3. Implement reflection mathematics:
	- `calculate_reflection(point: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2`
	- Find perpendicular distance to mirror line
	- Reflect across line
	- Return reflected position
4. Implement direction reflection:
	- `calculate_direction_reflection(direction: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2`
	- Reflect direction vector across mirror normal
	- Return reflected direction
5. Implement `_validate()`:
	- Check mirror line within range
	- Check reflected position within bounds
	- **CRITICAL**: Mirrorwalk IGNORES barriers (passes through walls)
6. Implement `_execute()`:
	- Store original position and direction
	- Calculate reflected position
	- Calculate reflected direction
	- Animate reflection effect
	- Update position and direction
7. Implement `_preview()`:
	- Show mirror line (cyan color #00BCD4)
	- Show ghost at reflected position
	- Show reflection path (dotted line)
	- Indicate that barriers will be passed
8. Implement visual effects:
	- Mirror shimmer effect along mirror line
	- Ripple distortion during reflection
	- Cyan glow particles
9. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Reflection math is correct (test with known cases)
- [ ] Passes through barriers correctly
- [ ] Direction reflection works
- [ ] Preview shows mirror line and ghost
- [ ] Visual effects display
- [ ] Range scaling with level works
- [ ] Edge cases handled (corners, endpoints)

---

### Task 3.3: Pivot (Self-Rotation)
**Dependencies**: Task 2.2  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create `res://scripts/transformations/pivot.gd` extending TransformationBase
2. Implement parameters:
	- `angle_degrees: float` - Rotation angle (45°, 90°, 135°, 180°, etc.)
	- `clockwise: bool` - Rotation direction
3. Implement `_validate()`:
	- Always valid (no range check for self-rotation)
	- Return true
4. Implement `_execute()`:
	- Store original direction
	- Rotate current_direction by angle
	- Apply angle snapping if GameManager.angle_snap enabled
	- Snap to nearest 45° direction
	- Update sprite direction
	- **Position unchanged** (rotation in place)
5. Implement `_undo()`:
	- Restore original direction
6. Implement `_preview()`:
	- Show rotation arc indicator
	- Show arrow indicating final direction
	- Amber color (#FFA726)
7. Implement visual effects:
	- Spinning amber particles
	- Rotation trail effect
	- Quick rotation animation (0.2 seconds)
8. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Rotation updates direction only (position unchanged)
- [ ] Angle snapping works correctly
- [ ] Preview shows rotation arc
- [ ] Visual effects display
- [ ] Undo works correctly

---

### Task 3.4: Shadow Pivot (External Rotation)
**Dependencies**: Task 2.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/transformations/shadow_pivot.gd` extending TransformationBase
2. Implement parameters:
	- `anchor_point: Vector2` - Center of rotation
	- `angle_degrees: float` - Rotation angle
	- `target: Node2D` - What to rotate
3. Implement rotation mathematics:
	- `rotate_point_around_pivot(point: Vector2, pivot: Vector2, angle_rad: float) -> Vector2`
	- Translate to origin: `point - pivot`
	- Rotate by angle using rotation matrix
	- Translate back: `+ pivot`
	- Return rotated position
4. Implement `_validate()`:
	- Check anchor point within range (level-based)
	- Check target within range of anchor
	- Check final position within bounds
	- Unlocked at level 3+
5. Implement `_execute()`:
	- Store original position and direction
	- Calculate rotated position
	- Calculate rotated direction
	- Animate orbital motion
	- Update position and direction
	- **Both position AND direction change**
6. Implement `_undo()`:
	- Restore original position and direction
7. Implement `_preview()`:
	- Show anchor point (amber circle)
	- Show tether line from target to anchor
	- Show rotation arc
	- Show ghost at final position
	- Amber color (#FFA726)
8. Implement visual effects:
	- Orbital spark trail
	- Amber tether line
	- Arc motion path
	- Smooth orbital animation (0.4 seconds)
9. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Rotation math is correct (test known cases)
- [ ] Both position and direction update
- [ ] Preview shows anchor, tether, and arc
- [ ] Visual effects display
- [ ] Range validation works (level-based)
- [ ] Undo restores both position and direction

---

### Task 3.5: Shadowshift (Dilation)
**Dependencies**: Task 2.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/transformations/shadowshift.gd` extending TransformationBase
2. Implement parameters:
	- `scale_factor: float` - New size (0.5 = 50%, 2.0 = 200%)
	- `center_point: Vector2` - Center of dilation
	- `persistent: bool` - Whether size change persists after turn
	- `target: Node2D` - What to scale
3. Implement dilation mathematics:
	- `apply_dilation(point: Vector2, center: Vector2, factor: float) -> Vector2`
	- Translate to origin: `point - center`
	- Scale: `* factor`
	- Translate back: `+ center`
	- Return dilated position
4. Implement `_validate()`:
	- Check ability unlocked for target type:
		- Level 2+: SELF
		- Level 4+: OBJECT
		- Level 6+: ENEMY
	- Check scale factor within bounds (0.5 to 2.0)
	- Check final size fits in arena
	- Only available on ODD player levels
5. Implement `_execute()`:
	- Store original scale and position
	- Calculate new position (if center != target position)
	- Apply scale to sprite
	- Apply scale to collision shape
	- Update size-dependent properties
	- If persistent: mark as new base size
	- If instantaneous: revert after turn ends
6. Implement `_undo()`:
	- Restore original scale and position
7. Implement `_preview()`:
	- Show ghost at new size and position
	- Show center point indicator
	- Show dilation lines
	- Violet color (#9C27B0)
8. Implement visual effects:
	- Pulsing violet aura
	- Size change animation (0.3 seconds)
	- Particle burst at scale change
9. Implement size-restricted passage interaction:
	- Update collision shape radius
	- Check passage width against new size
10. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Dilation math is correct
- [ ] Size change applies to sprite and collision
- [ ] Persistent vs instantaneous mode works
- [ ] Preview shows new size correctly
- [ ] Visual effects display
- [ ] Target type unlock progression works (level 2/4/6)
- [ ] Only available on odd levels
- [ ] Undo restores original size

---

### Task 3.6: Integration Testing for Transformations
**Dependencies**: Tasks 3.1-3.5  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create test scene `res://scenes/test/transformation_test.tscn`:
	- TileMap with barriers
	- Player avatar
	- Test objects (crates, blocks)
	- UI buttons for each transformation
2. Create test script `res://scripts/test/transformation_test.gd`:
	- Test each transformation independently
	- Test edge cases:
		- Shadow Slide hitting barriers
		- Mirrorwalk passing through barriers
		- Rotation boundary cases
		- Scaling at edges
	- Test undo/redo for each
	- Test range validation at different levels
3. Create validation checks:
	- Position after transformation is correct
	- Direction after transformation is correct
	- Barriers respected (Shadow Slide) or ignored (Mirrorwalk)
	- Range limits enforced
	- Visual effects display correctly
4. Document test results in comments

**Human Checkpoint**: When done, remind the user to verify:
- [ ] All transformations execute without errors
- [ ] Shadow Slide stops at barriers
- [ ] Mirrorwalk passes through barriers
- [ ] Rotation calculations are accurate
- [ ] Scaling works correctly
- [ ] Range validation works at different levels
- [ ] Undo/redo functions work for all transformations
- [ ] Visual effects display for all transformations

---

## PHASE 4: Turn-Based Combat System
**Goal**: Implement three-phase turn system with enemy AI

### Task 4.1: Turn Manager Core System
**Dependencies**: Task 2.5  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/systems/turn_manager.gd`
2. Define turn phases enum:
	```gdscript
	enum Phase {
		IDLE,
		ENEMY_TELEGRAPH,
		PLAYER_ACTION,
		ENEMY_RESOLUTION,
		LEVEL_COMPLETE,
		LEVEL_FAILED
	}
	```
3. Implement phase management:
	- `current_phase: Phase`
	- `turn_number: int`
	- `phase_transition(new_phase: Phase) -> void`
	- `get_current_phase() -> Phase`
4. Implement turn cycle:
	- `start_turn() -> void`
		1. Increment turn_number
		2. Enter ENEMY_TELEGRAPH phase
	- `end_telegraph_phase() -> void`
		- Transition to PLAYER_ACTION
		- Start turn timer (Hard mode only)
	- `end_player_action() -> void`
		- Validate player's transformation
		- Transition to ENEMY_RESOLUTION
	- `end_resolution_phase() -> void`
		- Check win/lose conditions
		- If continue: start_turn()
		- If won: LEVEL_COMPLETE
		- If lost: LEVEL_FAILED
5. Implement action queue:
	- `player_action: TransformationBase`
	- `enemy_actions: Array[Dictionary]` - Stores telegraphed actions
6. Implement turn timer (Hard mode):
	- `turn_time_limit: float = 20.0`
	- `turn_time_remaining: float`
	- `_process(delta)` counts down in PLAYER_ACTION phase
	- Auto-pass if timer expires
7. Add signals:
	- `phase_changed(new_phase: Phase)`
	- `turn_started(turn_number: int)`
	- `turn_ended()`
	- `timer_warning(seconds_remaining: float)` - at 5 seconds
	- `timer_expired()`
8. Use tabs for indentation
9. Make singleton (AutoLoad):
	- Path: `res://scripts/systems/turn_manager.gd`
	- Name: `TurnManager`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured
- [ ] Phase transitions work correctly
- [ ] Turn cycle completes properly
- [ ] Turn timer works (test in Hard mode)
- [ ] Signals emit correctly
- [ ] Action queue stores data correctly

---

### Task 4.2: Telegraph System
**Dependencies**: Task 4.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/systems/telegraph_system.gd`
2. Implement telegraph display modes:
	- `TelegraphMode` enum: SEQUENTIAL, SIMULTANEOUS
	- Get mode from difficulty settings
3. Implement telegraph indicators:
	- `create_telegraph_indicator(enemy: Node2D, action_type: String, target_pos: Vector2) -> Node2D`
	- Create visual indicator based on enemy type:
		- Hound: Dotted line path (yellow #FFC107)
		- Mirror Wraith: Cyan glow + "COPY READY" text
		- Hollow Sentinel: Light beam preview (red #F44336)
	- Return indicator node
4. Implement sequential telegraph:
	- `show_sequential_telegraphs(enemies: Array[Node2D]) -> void`
	- For each enemy:
		- Create telegraph indicator
		- Play telegraph animation (0.5-1.0 sec per enemy)
		- Wait for animation complete
		- Next enemy
	- Store all indicators
	- In Easy mode: keep visible
	- In Normal mode: fade after 1-2 seconds
5. Implement simultaneous telegraph:
	- `show_simultaneous_telegraphs(enemies: Array[Node2D]) -> void`
	- Create all telegraph indicators at once
	- Play all animations in parallel
	- Fade immediately after animations
6. Implement telegraph clearing:
	- `clear_telegraphs() -> void`
	- Remove all telegraph indicators
7. Implement difficulty-specific features:
	- Easy: show ghost preview of enemy end positions
	- Normal: no ghost previews
	- Hard: minimal indicators, fast fade
8. Add telegraph data caching:
	- Store enemy intentions in TurnManager.enemy_actions
9. Use tabs for indentation
10. Make singleton (AutoLoad):
	- Path: `res://scripts/systems/telegraph_system.gd`
	- Name: `TelegraphSystem`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured
- [ ] Sequential mode shows one enemy at a time
- [ ] Simultaneous mode shows all enemies at once
- [ ] Indicators display correctly for each enemy type
- [ ] Fade behavior matches difficulty settings
- [ ] Ghost previews work in Easy mode only
- [ ] Telegraph data cached correctly

---

### Task 4.3: Combat Resolution System
**Dependencies**: Task 4.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/systems/combat_resolver.gd`
2. Implement enemy action execution:
	- `execute_enemy_actions(enemy_actions: Array[Dictionary]) -> void`
	- For each enemy (sequential order):
		- Get enemy's cached action
		- Execute action from NEW position (after player transformation)
		- Animate enemy movement
		- Check for player contact
		- Check for enemy-enemy collision
		- Check for hazard interaction
		- If player hit: trigger level reset
		- If enemy hits hazard: remove enemy
3. Implement collision detection:
	- `check_player_collision(enemy: Node2D) -> bool`
		- Check if enemy overlaps player
		- Return true if collision detected
	- `check_enemy_enemy_collision(enemy: Node2D, others: Array[Node2D]) -> bool`
		- Check if enemy overlaps other enemies
		- Enemies block each other's movement
		- Return true if collision
	- `check_hazard_collision(entity: Node2D) -> bool`
		- Check if entity overlaps hazard tile
		- Return true if on hazard
4. Implement resolution order:
	- Enemies resolve in sequence (not simultaneously)
	- First enemy to hit player triggers reset
	- Enemy-enemy collision stops movement
5. Implement level reset on failure:
	- `trigger_level_reset() -> void`
	- Stop all enemy actions
	- Reset player to start position
	- Reset enemies to start positions
	- Reset turn counter
	- Increment GameManager.resets_used
6. Implement win condition checking:
	- `check_victory_conditions() -> bool`
	- Player reached exit
	- All required objectives complete
	- Return true if won
7. Implement enemy removal:
	- `remove_enemy(enemy: Node2D) -> void`
	- Play death animation
	- Remove from scene
	- Update bestiary if first time
8. Add signals:
	- `enemy_action_started(enemy: Node2D)`
	- `enemy_action_complete(enemy: Node2D)`
	- `player_hit(enemy: Node2D)`
	- `enemy_defeated(enemy: Node2D)`
	- `victory()`
9. Use tabs for indentation
10. Make singleton (AutoLoad):
	- Path: `res://scripts/systems/combat_resolver.gd`
	- Name: `CombatResolver`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured
- [ ] Enemies execute actions sequentially
- [ ] Actions execute from NEW positions after player transformation
- [ ] Player collision detection works
- [ ] Enemy-enemy collision blocks movement
- [ ] Hazard collision removes enemies
- [ ] Level reset triggers on player hit
- [ ] Victory detection works
- [ ] Signals emit correctly

---

### Task 4.4: Turn System Integration
**Dependencies**: Tasks 4.1-4.3, Task 2.5  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Update `res://scripts/player/player_avatar.gd`:
	- Connect to TurnManager signals
	- Enable/disable input based on current phase
	- Only accept input during PLAYER_ACTION phase
	- Submit transformation to TurnManager on confirm
2. Update TurnManager to orchestrate full turn:
	```gdscript
	func execute_turn_cycle() -> void:
		# Phase 1: Enemy Telegraph
		current_phase = Phase.ENEMY_TELEGRAPH
		var enemies := get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			enemy.calculate_next_action()  # Enemy decides what to do
		
		var telegraph_mode = get_telegraph_mode()  # From difficulty
		if telegraph_mode == TelegraphMode.SEQUENTIAL:
			await TelegraphSystem.show_sequential_telegraphs(enemies)
		else:
			await TelegraphSystem.show_simultaneous_telegraphs(enemies)
		
		end_telegraph_phase()
		
		# Phase 2: Player Action
		current_phase = Phase.PLAYER_ACTION
		if is_hard_mode():
			start_turn_timer()
		# Wait for player input (transformation submission)
		await player_action_submitted
		
		end_player_action()
		
		# Phase 3: Enemy Resolution
		current_phase = Phase.ENEMY_RESOLUTION
		await CombatResolver.execute_enemy_actions(enemy_actions)
		
		# Check win/lose
		if CombatResolver.check_victory_conditions():
			current_phase = Phase.LEVEL_COMPLETE
			emit_signal("level_complete")
		elif player was hit:
			current_phase = Phase.LEVEL_FAILED
			emit_signal("level_failed")
		else:
			# Continue to next turn
			execute_turn_cycle()
	```
3. Create test level with turn system:
	- One Hound enemy
	- Player avatar
	- Exit tile
	- Test complete turn cycle
4. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Complete turn cycle executes without errors
- [ ] Player can only act during PLAYER_ACTION phase
- [ ] Telegraph phase displays correctly
- [ ] Enemy resolution executes from new positions
- [ ] Victory detection triggers correctly
- [ ] Failure triggers level reset
- [ ] Next turn starts after successful resolution
- [ ] Turn timer works in Hard mode

---

## PHASE 5: Enemy Implementation
**Goal**: Create all enemy types with unique behaviors

### Task 5.1: Enemy Base Class Enhancement
**Dependencies**: Task 4.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Review existing `res://enemy_base.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/enemies/enemy_base.gd` extending CharacterBody2D
3. Implement core enemy properties:
	- `enemy_type: String` - "hound", "wraith", "sentinel", "architect"
	- `health: int` - Hit points (most have 1)
	- `current_tile: Vector2i` - Grid position
	- `current_direction: Vector2` - Facing direction
	- `movement_speed: float` - For animations
	- `is_active: bool` - Whether enemy is alive
	- `telegraph_data: Dictionary` - Cached next action
4. Implement state machine:
	```gdscript
	enum State {
		IDLE,
		TELEGRAPHING,
		WAITING,
		EXECUTING,
		DEAD
	}
	var current_state: State = State.IDLE
	```
5. Implement virtual methods (to override in subclasses):
	- `calculate_next_action() -> Dictionary` - AI decision
	- `execute_action(action: Dictionary) -> void` - Perform action
	- `telegraph_action(action: Dictionary) -> void` - Visual preview
	- `take_damage(amount: int) -> void` - Handle damage
	- `die() -> void` - Death animation
6. Implement common behaviors:
	- `move_to_tile(target_tile: Vector2i) -> void`
		- Check if path is clear
		- Move if possible
		- Stop if blocked by another enemy
	- `face_direction(direction: Vector2) -> void`
		- Update sprite orientation
	- `get_tiles_in_vision(range: int) -> Array[Vector2i]`
		- Return tiles enemy can "see"
7. Implement AI decision framework:
	- `detect_player() -> bool` - Check if player in range
	- `get_path_to_player() -> Array[Vector2i]` - A* pathfinding
	- `is_path_clear(path: Array[Vector2i]) -> bool` - Check obstacles
8. Add signals:
	- `action_calculated(action: Dictionary)`
	- `action_executed()`
	- `enemy_died()`
9. Connect to transformation system:
	- Enemies can be targets of player transformations
	- Store original intended action even after being moved
	- Execute action from NEW position
10. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Virtual methods defined correctly
- [ ] State machine logic is sound
- [ ] Pathfinding functions work
- [ ] Movement respects enemy-enemy collision
- [ ] Signals defined correctly
- [ ] Can be targeted by transformations

---

### Task 5.2: Hound of the Pale Implementation
**Dependencies**: Task 5.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Review existing `res://hound.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/enemies/hound.gd` extending enemy_base.gd
3. Implement Hound-specific properties per GDD:
	- `patrol_points: Array[Vector2i]` - Patrol path
	- `patrol_index: int = 0` - Current patrol target
	- `chase_range: int = 4` - Tiles to detect player
	- `pounce_damage: int = 1` - One-hit kill
4. Implement AI behavior:
	- `calculate_next_action() -> Dictionary`:
		```gdscript
		# Priority system:
		# 1. If player within 1 tile: Pounce
		# 2. If player within chase_range: Chase (pathfind toward player)
		# 3. Else: Patrol (move to next patrol point)
		
		if player_adjacent():
			return {type: "pounce", target: player_position}
		elif detect_player():
			return {type: "chase", target: get_next_chase_tile()}
		else:
			return {type: "patrol", target: get_next_patrol_point()}
		```
5. Implement action execution:
	- `execute_pounce(target_pos: Vector2i) -> void`
		- Quick lunge animation to target tile
		- If player on target: hit player
	- `execute_chase(target_pos: Vector2i) -> void`
		- Move one tile toward player using A* path
		- Update direction to face movement
	- `execute_patrol(target_pos: Vector2i) -> void`
		- Move to next patrol point
		- Cycle through patrol points
6. Implement telegraph visualization:
	- Patrol: Yellow dotted line showing path
	- Chase: Red dotted line toward player
	- Pounce: Red pounce arc indicator
7. Handle transformation effects:
	- Remember intended action even if moved
	- Execute from NEW position after player transformation
	- Pathfinding recalculates from new position
8. Implement sprite animation:
	- 4-direction sprite (N, E, S, W)
	- Walk animation
	- Pounce animation
	- Idle animation
9. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Patrol behavior works correctly
- [ ] Chase behavior activates within range
- [ ] Pounce triggers when adjacent
- [ ] Pathfinding works from any position
- [ ] Actions execute from new position after transformation
- [ ] Telegraph shows correct action type
- [ ] Hit detection triggers level reset

---

### Task 5.3: Mirror Wraith Implementation
**Dependencies**: Task 5.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Review existing `res://mirror_wraith.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/enemies/mirror_wraith.gd` extending enemy_base.gd
3. Implement Mirror Wraith-specific properties per GDD:
	- `mimic_range: int = 6` - Tiles to observe player
	- `can_phase: bool = true` - Passes through walls
	- `last_player_transformation: String` - What to copy
4. Implement AI behavior:
	- `calculate_next_action() -> Dictionary`:
		```gdscript
		# Mirror Wraith copies player's LAST transformation
		# If player used Shadow Slide right: Wraith uses Shadow Slide right
		# If player used Mirrorwalk: Wraith uses Mirrorwalk
		# If player within melee range: Attack instead
		
		if player_adjacent():
			return {type: "attack", target: player_position}
		elif detect_player():
			var last_transform = get_player_last_transformation()
			return {type: "mimic", ability: last_transform.type, params: last_transform.params}
		else:
			return {type: "phase", target: random_nearby_tile()}
		```
5. Implement mimic ability:
	- `execute_mimic(ability: String, params: Dictionary) -> void`
		- Shadow Slide: Move in same direction
		- Mirrorwalk: Reflect self across mirror line
		- Pivot: Rotate in place
		- Shadow Pivot: Rotate around point
		- Shadowshift: Scale self
		- Apply same transformation Wraith used
6. Implement phase ability:
	- `execute_phase(target_pos: Vector2i) -> void`
		- Fade out animation
		- Teleport to target (passes through walls)
		- Fade in animation
		- Short range (2-3 tiles)
7. Implement telegraph visualization:
	- Mimic: Cyan glow + "COPY READY" text
	- Show what ability will be copied
	- Easy mode: Show ghost preview of end position
	- Phase: Cyan shimmer at target location
8. Handle transformation effects:
	- Wraith can be transformed by player
	- Intended mimic still executes from new position
	- Example: Player slides Wraith north, Wraith still copies player's last move
9. Implement sprite animation:
	- Translucent/ghostly appearance (modulate alpha 0.7-0.9)
	- Floating animation (bobbing up/down)
	- Shimmer effect
	- Fade in/out for phase
10. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Mimic behavior copies player's last transformation
- [ ] Phase ability passes through walls
- [ ] Telegraph shows "COPY READY" correctly
- [ ] Attack triggers when adjacent
- [ ] Transformations apply to Wraith correctly
- [ ] Mimic executes from new position after being transformed
- [ ] Ghost preview works in Easy mode

---

### Task 5.4: Hollow Sentinel Implementation
**Dependencies**: Task 5.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Review existing `res://hollow_sentinel.gd` for reference ONLY (do not copy directly)
2. Create NEW `res://scripts/enemies/hollow_sentinel.gd` extending enemy_base.gd
3. Implement Hollow Sentinel-specific properties per GDD:
	- `beam_range: int = 8` - Beam attack range
	- `rotation_speed: float = 90.0` - Degrees per turn
	- `shield_active: bool = false` - Front shield state
	- `shield_direction: Vector2` - Shield facing
4. Implement AI behavior:
	- `calculate_next_action() -> Dictionary`:
		```gdscript
		# Sentinel rotates to face player, then fires beam
		# Has shield that blocks attacks from one direction
		
		var angle_to_player = get_angle_to_player()
		
		if is_facing_player():
			return {type: "beam", direction: current_direction, range: beam_range}
		else:
			# Rotate toward player
			var rotate_amount = calculate_rotation_to_face_player()
			return {type: "rotate", angle: rotate_amount}
		```
5. Implement beam attack:
	- `execute_beam(direction: Vector2, range: int) -> void`
		- Fire beam in direction for range tiles
		- Check each tile along beam path
		- If player hit: trigger level reset
		- Beam passes through enemies (friendly fire!)
		- Beam stops at walls
	- Visual: Bright red beam line (#F44336)
	- Animation: Charging glow, then beam fire (0.3 sec)
6. Implement rotation behavior:
	- `execute_rotate(angle: float) -> void`
		- Rotate to new facing direction
		- Update shield_direction
		- Rotation limited to 90° per turn
7. Implement shield system:
	- `has_shield_facing(direction: Vector2) -> bool`
		- Check if attack coming from shield direction
		- Block damage from that direction
	- Shield blocks player transformations from front
	- Must attack from sides or behind
8. Implement telegraph visualization:
	- Beam: Red line showing beam path and range
	- Rotation: Curved arrow showing rotation direction
	- Show beam will hit player (red warning)
9. Handle transformation effects:
	- If player rotates Sentinel: beam fires in NEW direction
	- Example: Sentinel faces north, player rotates 90°, beam fires east
	- If player moves Sentinel: beam fires from NEW position
10. Implement sprite animation:
	- Large sprite (32x32)
	- Shield visual on front
	- Rotation animation
	- Beam charging glow
	- Beam firing effect
11. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Rotation behavior turns toward player
- [ ] Beam attack hits player correctly
- [ ] Beam range and path calculation correct
- [ ] Shield blocks attacks from front only
- [ ] Telegraph shows beam path clearly
- [ ] Rotation changes beam direction correctly
- [ ] Friendly fire works (beam can hit other enemies)
- [ ] Transformations affect beam direction/position

---

### Task 5.5: Enemy Scene Setup
**Dependencies**: Tasks 5.2-5.4  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create `res://scenes/enemies/hound.tscn`:
	- Root: CharacterBody2D (script: hound.gd)
	- ├── Sprite2D (16x16 placeholder - yellow square)
	- ├── CollisionShape2D (CircleShape2D, radius 6)
	- ├── NavigationAgent2D (for pathfinding)
	- ├── AnimationPlayer
	- └── TelegraphIndicator (Node2D) - for showing telegraph
2. Create `res://scenes/enemies/mirror_wraith.tscn`:
	- Root: CharacterBody2D (script: mirror_wraith.gd)
	- ├── Sprite2D (16x16 placeholder - cyan square, alpha 0.7)
	- ├── CollisionShape2D (CircleShape2D, radius 6)
	- ├── AnimationPlayer
	- ├── TelegraphIndicator (Node2D)
	- └── Particles2D (shimmer effect)
3. Create `res://scenes/enemies/hollow_sentinel.tscn`:
	- Root: CharacterBody2D (script: hollow_sentinel.gd)
	- ├── Sprite2D (32x32 placeholder - red square)
	- ├── ShieldSprite (Sprite2D) - visual shield on front
	- ├── CollisionShape2D (CircleShape2D, radius 12)
	- ├── BeamRayCast (RayCast2D) - for beam attack
	- ├── AnimationPlayer
	- └── TelegraphIndicator (Node2D)
4. Set collision layers for all enemies:
	- Layer 3 (enemies)
	- Mask: layers 1 (player), 2 (walls), 3 (enemies)
5. Add to "enemies" group for easy access
6. Configure NavigationAgent2D for pathfinding (Hound only)

**Human Checkpoint**: When done, remind the user to verify:
- [ ] All enemy scenes open without errors
- [ ] Collision shapes visible in editor
- [ ] Sprites display correctly
- [ ] Collision layers set correctly
- [ ] NavigationAgent2D configured (Hound)
- [ ] Can instantiate enemies in test scene
- [ ] Scripts attached correctly

---

### Task 5.6: Enemy AI Integration Testing
**Dependencies**: Task 5.5, Task 4.4  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create test level `res://scenes/test/enemy_ai_test.tscn`:
	- TileMap with walls and corridors
	- Player avatar
	- One of each enemy type
	- Exit tile
2. Test each enemy individually:
	- Hound:
		- Test patrol behavior
		- Test chase activation
		- Test pounce when adjacent
		- Test pathfinding around walls
	- Mirror Wraith:
		- Test mimic of each transformation type
		- Test phase through walls
		- Test attack when adjacent
	- Hollow Sentinel:
		- Test rotation toward player
		- Test beam attack
		- Test beam collision with player
		- Test shield blocking from front
3. Test transformation effects on enemies:
	- Move enemy with Shadow Slide
	- Verify action executes from new position
	- Rotate enemy with Shadow Pivot
	- Verify action executes in new direction
4. Test telegraph system:
	- Sequential mode (Easy/Normal)
	- Simultaneous mode (Hard)
	- Verify indicators display correctly
5. Test turn cycle with enemies:
	- Complete turn with enemy action
	- Verify player can act
	- Verify enemy executes after player
6. Document test results

**Human Checkpoint**: When done, remind the user to verify:
- [ ] All enemy behaviors work correctly
- [ ] Patrol, chase, pounce work (Hound)
- [ ] Mimic and phase work (Mirror Wraith)
- [ ] Rotation and beam work (Hollow Sentinel)
- [ ] Enemies execute from new positions after transformation
- [ ] Telegraph displays correctly for all enemies
- [ ] Turn cycle completes successfully
- [ ] Player hit triggers level reset

---

## PHASE 6: Level Design System
**Goal**: Create level loading system and training levels (Levels 1-4)

### Task 6.1: Level Data Loader
**Dependencies**: Task 1.7, Task 2.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/levels/level_data.gd`:
2. Implement JSON level loading:
	- `load_level_data(level_number: int) -> Dictionary`
	- Read from `res://data/levels/level_{level_number:02d}.json`
	- Parse JSON using Godot's JSON class
	- Validate schema
	- Return level data dictionary
3. Implement level parsing:
	- `parse_arena_data(data: Dictionary) -> void`
		- Load TileMap data
		- Set arena bounds
	- `parse_entity_spawns(data: Dictionary) -> Array`
		- Parse player start position
		- Parse enemy positions and types
		- Parse hazard positions
		- Return spawn data array
	- `parse_objectives(data: Dictionary) -> Dictionary`
		- Parse primary and secondary objectives
		- Return objectives dict
	- `parse_tutorial_sequence(data: Dictionary) -> Array`
		- Parse tutorial steps
		- Return tutorial array
4. Implement data validation:
	- Check required fields present
	- Validate position coordinates
	- Validate enemy types exist
	- Check for logical errors
5. Add error handling:
	- Missing file
	- Invalid JSON
	- Schema mismatch
	- Provide helpful error messages
6. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Can load example level JSON
- [ ] Parsing functions extract data correctly
- [ ] Validation catches errors
- [ ] Error handling provides useful feedback

---

### Task 6.2: Enhanced Level Base Script
**Dependencies**: Task 6.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Update `res://scripts/levels/level_base.gd`:
2. Implement level initialization:
	- `initialize_level(level_number: int) -> void`
		- Load level data via level_data.gd
		- Setup arena (TileMap)
		- Spawn player at start position
		- Spawn enemies from data
		- Spawn hazards
		- Setup objectives
		- Initialize tutorial system (if tutorial level)
		- Start first turn
3. Implement entity spawning:
	- `spawn_player(position: Vector2i, direction: Vector2) -> void`
		- Instantiate player_avatar.tscn
		- Set position and direction
		- Add to scene
	- `spawn_enemies(enemy_data: Array) -> void`
		- For each enemy in data:
			- Load appropriate enemy scene
			- Set position
			- Set patrol points (if Hound)
			- Add to scene and "enemies" group
	- `spawn_hazards(hazard_data: Array) -> void`
		- Create hazard tiles
		- Setup collision detection
4. Implement objective tracking:
	- `objectives: Dictionary` - Current objectives
	- `check_objectives() -> bool` - Check if completed
	- `update_objective_progress() -> void`
	- Track secondary objectives (optional)
5. Implement level completion:
	- `on_level_complete() -> void`
		- Award XP
		- Save progress
		- Show victory screen
		- Unlock next level
6. Implement level reset:
	- `reset_level() -> void`
		- Clear all entities
		- Re-initialize from data
		- Reset turn counter
		- Increment resets_used
7. Connect to TurnManager:
	- Listen for victory/failure signals
	- Trigger appropriate responses
8. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script compiles without errors
- [ ] Level initialization works
- [ ] Entities spawn correctly from JSON data
- [ ] Player spawns at correct position
- [ ] Enemies spawn with correct types and positions
- [ ] Objectives track progress
- [ ] Level completion triggers correctly
- [ ] Level reset works

---

### Task 6.3: Tutorial System
**Dependencies**: Task 6.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **ON**."

**Implementation**:
1. Create `res://scripts/systems/tutorial_system.gd`:
2. Define tutorial step structure:
	```gdscript
	class TutorialStep:
		var step_number: int
		var text: String
		var wait_for_input: bool
		var required_action: String  # "shadow_slide", "reach_position", etc.
		var mastery_count: int  # How many times to repeat
		var highlight_area: Rect2i  # Area to highlight
	```
3. Implement tutorial flow:
	- `start_tutorial(sequence: Array[TutorialStep]) -> void`
		- Load tutorial sequence
		- Show first step
	- `advance_tutorial() -> void`
		- Check if step requirements met
		- Move to next step
		- If complete: end tutorial
	- `end_tutorial() -> void`
		- Clear tutorial UI
		- Enable normal gameplay
4. Implement tutorial UI:
	- `show_tutorial_message(text: String) -> void`
		- Display message box
		- Position at top or bottom of screen
		- Add "Continue" button if wait_for_input
	- `hide_tutorial_message() -> void`
	- `highlight_area(rect: Rect2i) -> void`
		- Darken rest of screen
		- Highlight specific area
		- Draw attention to important elements
5. Implement mastery checks:
	- `track_action(action: String) -> void`
		- Count specific actions
		- Check against mastery_count
		- Advance when mastery achieved
	- `reset_mastery_counter() -> void`
6. Implement tutorial hints:
	- Show transformation preview
	- Show valid target areas
	- Provide hints after failures
7. Add signals:
	- `tutorial_step_started(step: int)`
	- `tutorial_step_complete(step: int)`
	- `tutorial_complete()`
8. Use tabs for indentation
9. Make singleton (AutoLoad):
	- Path: `res://scripts/systems/tutorial_system.gd`
	- Name: `TutorialSystem`

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Script runs without errors
- [ ] AutoLoad configured
- [ ] Tutorial steps display correctly
- [ ] Mastery checks track actions
- [ ] Advancement works correctly
- [ ] Highlight system works
- [ ] Tutorial UI displays properly
- [ ] Signals emit at correct times

---

### Task 6.4: Level 1 - Shadow Slide Trial
**Dependencies**: Task 6.3  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create level JSON `res://data/levels/level_01.json` per GDD Section 7.1:
	```json
	{
		"level_number": 1,
		"name": "Shadow Slide Trial",
		"type": "training",
		"duration_estimate_minutes": 10,
		"difficulty_stars": 1,
		"learning_objectives": [
			"Introduce Shadow Slide (translation)",
			"Teach clicking and dragging",
			"Demonstrate barriers block Shadow Slide"
		],
		"arena": {
			"width_tiles": 40,
			"height_tiles": 25
		},
		"player_start": {
			"position": [5, 12],
			"direction": [1, 0]
		},
		"objectives": {
			"primary": "Reach the exit",
			"secondary": []
		},
		"enemies": [],
		"hazards": [
			{"type": "spike_trap", "position": [15, 12]},
			{"type": "spike_trap", "position": [20, 12]}
		],
		"barriers": [
			{"start": [10, 10], "end": [10, 14]},
			{"start": [25, 10], "end": [25, 14]}
		],
		"exit": {"position": [35, 12]},
		"tutorial_sequence": [
			{
				"step": 1,
				"text": "Welcome, apprentice. You seek to master the Shadow Arts—transformations that reshape reality itself.",
				"wait_for_input": true
			},
			{
				"step": 2,
				"text": "The first art is Shadow Slide: moving without rotation. In mathematics, this is called translation.",
				"wait_for_input": true
			},
			{
				"step": 3,
				"text": "Click on yourself, then drag to a new position to perform Shadow Slide.",
				"wait_for_input": false,
				"required_action": "shadow_slide",
				"mastery_count": 1
			},
			{
				"step": 4,
				"text": "Excellent. Now practice sliding in different directions.",
				"wait_for_input": false,
				"required_action": "shadow_slide",
				"mastery_count": 3
			},
			{
				"step": 5,
				"text": "Beware: Shadow Slide cannot pass through barriers. Try it.",
				"wait_for_input": false,
				"required_action": "shadow_slide_blocked",
				"mastery_count": 1
			},
			{
				"step": 6,
				"text": "But hazards can be crossed safely with Shadow Slide. Now reach the exit.",
				"wait_for_input": false
			}
		],
		"xp_reward": 100,
		"unlocks_level": 2
	}
	```
2. Create level scene `res://scenes/levels/training/level_01.tscn`:
	- Use level_template.tscn as base
	- Attach level_base.gd script
	- Set level_number = 1
	- Design TileMap layout:
		- Open corridor from start to exit
		- Barriers at positions from JSON
		- Hazards at positions from JSON
		- Exit marker at end
3. Test level:
	- Load level through LevelManager
	- Verify tutorial sequence works
	- Verify mastery checks work
	- Verify barrier blocks Shadow Slide
	- Verify reaching exit completes level
4. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Level JSON is valid
- [ ] Level scene loads without errors
- [ ] Tutorial displays correctly
- [ ] Shadow Slide works
- [ ] Barriers block Shadow Slide
- [ ] Hazards don't block Shadow Slide
- [ ] Reaching exit completes level
- [ ] XP awarded correctly
- [ ] Level 2 unlocks

---

### Task 6.5: Level 2 - Mirrorwalk Trial
**Dependencies**: Task 6.4  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create level JSON `res://data/levels/level_02.json` per GDD Section 7.2:
	- Name: "Mirrorwalk Trial"
	- Learning objectives: Introduce Mirrorwalk, place mirror walls, bypass barriers
	- Arena: 40x25 tiles
	- Tutorial sequence per GDD
	- Mastery checks: place mirror 3 times, reflect to marked positions 3 times
	- XP reward: 100
	- Unlocks: Level 3, Shadowshift (self)
2. Create level scene `res://scenes/levels/training/level_02.tscn`:
	- TileMap with barriers
	- Marked target positions for practice
	- Exit beyond barrier (requires Mirrorwalk to reach)
3. Implement mirror wall placement mechanic:
	- Click and drag to place mirror line
	- Preview mirror line while dragging
	- Confirm placement
	- Execute Mirrorwalk across mirror
4. Test level thoroughly
5. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Level loads correctly
- [ ] Tutorial teaches Mirrorwalk
- [ ] Mirror placement works
- [ ] Mirrorwalk passes through barriers
- [ ] Mastery checks work
- [ ] Exit requires Mirrorwalk to reach
- [ ] Level completes correctly
- [ ] Shadowshift (self) unlocks

---

### Task 6.6: Level 3 - Pivot Trial
**Dependencies**: Task 6.5  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create level JSON `res://data/levels/level_03.json` per GDD Section 7.3:
	- Name: "Pivot & Shadow Pivot Trial"
	- Two-part tutorial: Pivot (self-rotation), then Shadow Pivot (external rotation)
	- Introduce directional gates (only pass if facing correctly)
	- Maze-like structure with gates
	- Shadow Pivot unlocks mid-level
	- XP reward: 100
	- Unlocks: Level 4, Shadow Pivot ability, Split Power (2 targets)
2. Create level scene `res://scenes/levels/training/level_03.tscn`:
	- Maze with directional gates
	- Corners requiring Shadow Pivot to navigate
	- Exit beyond final gate
3. Implement directional gates:
	- Create gate script
	- Check player facing direction
	- Open if facing correct direction
	- Visual indicator of required direction
4. Test level thoroughly
5. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Level loads correctly
- [ ] Pivot tutorial works
- [ ] Directional gates work
- [ ] Shadow Pivot unlocks mid-level
- [ ] Shadow Pivot navigation works
- [ ] Mastery checks pass
- [ ] Level completes correctly
- [ ] Shadow Pivot and Split Power unlock

---

### Task 6.7: Level 4 - Shadowshift Trial
**Dependencies**: Task 6.6  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask the human: "Is extended thinking on? For this task, it should be **OFF**."

**Implementation**:
1. Create level JSON `res://data/levels/level_04.json` per GDD Section 7.4:
	- Name: "Shadowshift Trial"
	- Introduce Shadowshift (dilation/scaling)
	- Teach size-restricted passages
	- Pressure plates requiring different sizes
	- Multi-section course
	- XP reward: 100
	- Unlocks: Level 5, Shadowshift (object), Combo 2
2. Create level scene `res://scenes/levels/training/level_04.tscn`:
	- Narrow passages (require shrinking)
	- Pressure plates (require normal/large size)
	- Size-restricted gates
	- Exit beyond final challenge
3. Implement narrow passages:
	- Check player size vs passage width
	- Block if too large
	- Allow if small enough
4. Implement pressure plates:
	- Check player size/weight
	- Activate if size >= threshold
	- Open gates when activated
5. Test level thoroughly
6. Use tabs for indentation

**Human Checkpoint**: When done, remind the user to verify:
- [ ] Level loads correctly
- [ ] Shadowshift tutorial works
- [ ] Size changes apply correctly
- [ ] Narrow passages block large player
- [ ] Pressure plates activate correctly
- [ ] Mastery checks pass
- [ ] Level completes correctly
- [ ] Shadowshift (object) and Combo 2 unlock

---

## End of Phase 6 Tasks

**NOTE TO HUMAN**: This completes Phases 1-6, bringing the project to **MVP status** with a playable game including:
- Complete project setup and core systems
- All four transformation abilities
- Turn-based combat system with three-phase turns
- Three enemy types (Hound, Mirror Wraith, Hollow Sentinel)
- Four tutorial levels (Shadow Slide, Mirrorwalk, Pivot, Shadowshift)

**Phases 7-11 (Boss Fight, UI/UX, Audio, Polish, Testing/Deployment) are post-MVP and should be tackled after confirming Phases 1-6 are working correctly.**

The task list can be extended with these phases once the MVP is stable. Would you like me to continue with Phases 7-11?
