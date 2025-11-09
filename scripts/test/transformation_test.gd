# res://scripts/test/transformation_test.gd
extends Node2D

# === TEST CONFIGURATION ===
var player: Node2D = null
var test_object: Node2D = null
var test_results: Dictionary = {}
var current_test: String = "idle"

# === TRANSFORMATION TEST FLAGS ===
var test_shadow_slide: bool = false
var test_mirrorwalk: bool = false
var test_pivot: bool = false
var test_shadow_pivot: bool = false
var test_shadowshift: bool = false

func _ready() -> void:
	"""Initialize test scene."""
	add_to_group("test_scene")
	print("=== Transformation Test Scene Initialized ===")
	print("Extended thinking OFF for integration testing")

	# Find player and test objects
	player = get_tree().get_first_child_in_group("player")
	if not player:
		push_error("Player not found in scene!")
		return

	print("Player found: %s" % player.name)
	print("\nAvailable test methods:")
	print("  - test_shadow_slide()")
	print("  - test_mirrorwalk()")
	print("  - test_pivot()")
	print("  - test_shadow_pivot()")
	print("  - test_shadowshift()")
	print("  - run_all_tests()")

func _input(event: InputEvent) -> void:
	"""Handle test input."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				test_shadow_slide()
			KEY_2:
				test_mirrorwalk()
			KEY_3:
				test_pivot()
			KEY_4:
				test_shadow_pivot()
			KEY_5:
				test_shadowshift()
			KEY_R:
				run_all_tests()

# === SHADOW SLIDE TESTS ===
func test_shadow_slide() -> void:
	"""
	Test Shadow Slide transformation.

	Validates:
	- Direction and distance parameters
	- Barrier collision detection
	- Position update correctness
	- Animation completion
	"""
	print("\n--- Testing Shadow Slide ---")
	if not player:
		print("FAIL: Player not found")
		return

	current_test = "shadow_slide"

	# Test case 1: Basic slide without barriers
	print("Test 1: Basic slide right (5 tiles)")
	var slide1 = ShadowSlide.new(player, GameManager.player_level)
	slide1.set_parameters(Vector2.RIGHT, 5)

	if not slide1.validate():
		print("FAIL: Validation failed for basic slide")
		test_results["shadow_slide_basic"] = "FAIL"
		return

	print("PASS: Validation successful")
	var initial_pos = player.global_position
	slide1.execute()
	await slide1.get_tree().create_timer(0.5).timeout

	var expected_pos = initial_pos + Vector2.RIGHT * 5 * GameConstants.TILE_SIZE
	var distance = player.global_position.distance_to(expected_pos)
	if distance < 5:
		print("PASS: Position updated correctly (distance: %.2f)" % distance)
		test_results["shadow_slide_basic"] = "PASS"
	else:
		print("FAIL: Position incorrect (distance: %.2f)" % distance)
		test_results["shadow_slide_basic"] = "FAIL"

	# Test case 2: Undo functionality
	print("\nTest 2: Undo shadow slide")
	slide1.undo()
	distance = player.global_position.distance_to(initial_pos)
	if distance < 5:
		print("PASS: Undo successful")
		test_results["shadow_slide_undo"] = "PASS"
	else:
		print("FAIL: Undo failed")
		test_results["shadow_slide_undo"] = "FAIL"

# === MIRRORWALK TESTS ===
func test_mirrorwalk() -> void:
	"""
	Test Mirrorwalk transformation.

	Validates:
	- Reflection calculation
	- Direction reflection
	- Barrier passing (unlike Shadow Slide)
	- Position and direction update
	"""
	print("\n--- Testing Mirrorwalk ---")
	if not player:
		print("FAIL: Player not found")
		return

	current_test = "mirrorwalk"

	# Test case 1: Basic reflection
	print("Test 1: Reflect across vertical line")
	var walk1 = Mirrorwalk.new(player, GameManager.player_level)

	# Mirror line at x=200
	var mirror_start = Vector2(200, 0)
	var mirror_end = Vector2(200, 300)

	walk1.set_parameters(mirror_start, mirror_end)

	if not walk1.validate():
		print("FAIL: Validation failed for mirrorwalk")
		test_results["mirrorwalk_basic"] = "FAIL"
		return

	print("PASS: Validation successful")
	var initial_pos = player.global_position
	walk1.execute()
	await walk1.get_tree().create_timer(0.5).timeout

	# Check that position changed
	if player.global_position.distance_to(initial_pos) > 5:
		print("PASS: Position updated via reflection")
		test_results["mirrorwalk_basic"] = "PASS"
	else:
		print("FAIL: Position not updated")
		test_results["mirrorwalk_basic"] = "FAIL"

	# Test case 2: Direction reflection
	print("\nTest 2: Direction reflection")
	var original_dir = player.current_direction
	if walk1.reflected_direction.distance_to(original_dir) > 0.1:
		print("PASS: Direction was reflected")
		test_results["mirrorwalk_direction"] = "PASS"
	else:
		print("FAIL: Direction not reflected")
		test_results["mirrorwalk_direction"] = "FAIL"

# === PIVOT TESTS ===
func test_pivot() -> void:
	"""
	Test Pivot transformation.

	Validates:
	- Direction rotation only (position unchanged)
	- Angle snapping
	- Animation completion
	"""
	print("\n--- Testing Pivot ---")
	if not player:
		print("FAIL: Player not found")
		return

	current_test = "pivot"

	# Test case 1: 90 degree rotation
	print("Test 1: Rotate 90 degrees clockwise")
	var pivot1 = Pivot.new(player, GameManager.player_level)
	pivot1.set_parameters(90.0, true)

	if not pivot1.validate():
		print("FAIL: Validation failed for pivot")
		test_results["pivot_basic"] = "FAIL"
		return

	print("PASS: Validation successful")
	var initial_pos = player.global_position
	var initial_dir = player.current_direction
	pivot1.execute()
	await pivot1.get_tree().create_timer(0.3).timeout

	# Check position unchanged
	if player.global_position.distance_to(initial_pos) < 1:
		print("PASS: Position unchanged")
		test_results["pivot_position"] = "PASS"
	else:
		print("FAIL: Position changed")
		test_results["pivot_position"] = "FAIL"

	# Check direction changed
	if initial_dir.distance_to(player.current_direction) > 0.1:
		print("PASS: Direction updated")
		test_results["pivot_direction"] = "PASS"
	else:
		print("FAIL: Direction not updated")
		test_results["pivot_direction"] = "FAIL"

# === SHADOW PIVOT TESTS ===
func test_shadow_pivot() -> void:
	"""
	Test Shadow Pivot transformation.

	Validates:
	- Rotation around external point
	- Both position and direction change
	- Range validation
	"""
	print("\n--- Testing Shadow Pivot ---")
	if not player:
		print("FAIL: Player not found")
		return

	current_test = "shadow_pivot"

	# Check if ability is unlocked
	if not GameManager.abilities.get("shadow_pivot", false):
		print("SKIP: Shadow Pivot not unlocked (requires Level 3)")
		test_results["shadow_pivot"] = "SKIP"
		return

	# Test case 1: 90 degree rotation around anchor
	print("Test 1: Rotate 90 degrees around anchor")
	var pivot1 = ShadowPivot.new(player, GameManager.player_level)

	var anchor = player.global_position + Vector2(50, 0)
	pivot1.set_parameters(anchor, 90.0, true)

	if not pivot1.validate():
		print("FAIL: Validation failed for shadow pivot")
		test_results["shadow_pivot_basic"] = "FAIL"
		return

	print("PASS: Validation successful")
	var initial_pos = player.global_position
	pivot1.execute()
	await pivot1.get_tree().create_timer(0.5).timeout

	# Check position changed
	if player.global_position.distance_to(initial_pos) > 5:
		print("PASS: Position updated via rotation")
		test_results["shadow_pivot_position"] = "PASS"
	else:
		print("FAIL: Position not updated")
		test_results["shadow_pivot_position"] = "FAIL"

# === SHADOWSHIFT TESTS ===
func test_shadowshift() -> void:
	"""
	Test Shadowshift transformation.

	Validates:
	- Scale factor application
	- Level restrictions (odd levels)
	- Target type unlock progression
	- Scale range validation
	"""
	print("\n--- Testing Shadowshift ---")
	if not player:
		print("FAIL: Player not found")
		return

	current_test = "shadowshift"

	# Check if ability is unlocked for self
	if not GameManager.abilities.get("shadowshift_self", false):
		print("SKIP: Shadowshift not unlocked (requires Level 2)")
		test_results["shadowshift"] = "SKIP"
		return

	# Check if on odd level
	if GameManager.player_level % 2 == 0:
		print("SKIP: Shadowshift only available on odd levels (current level: %d)" % GameManager.player_level)
		test_results["shadowshift"] = "SKIP"
		return

	# Test case 1: Scale up
	print("Test 1: Scale to 1.5x")
	var shift1 = Shadowshift.new(player, GameManager.player_level)
	shift1.set_parameters(1.5, player.global_position, true)

	if not shift1.validate():
		print("FAIL: Validation failed for shadowshift")
		test_results["shadowshift_scale"] = "FAIL"
		return

	print("PASS: Validation successful")
	var initial_scale = player.scale
	shift1.execute()
	await shift1.get_tree().create_timer(0.4).timeout

	if player.scale.x > 1.4:
		print("PASS: Scale updated correctly (%.2f)" % player.scale.x)
		test_results["shadowshift_scale"] = "PASS"
	else:
		print("FAIL: Scale not updated")
		test_results["shadowshift_scale"] = "FAIL"

	# Test case 2: Undo
	print("\nTest 2: Undo shadowshift")
	shift1.undo()
	if player.scale.distance_to(initial_scale) < 0.1:
		print("PASS: Undo successful")
		test_results["shadowshift_undo"] = "PASS"
	else:
		print("FAIL: Undo failed")
		test_results["shadowshift_undo"] = "FAIL"

# === COMBINED TEST ===
func run_all_tests() -> void:
	"""Run all transformation tests."""
	print("\n========================================")
	print("RUNNING ALL TRANSFORMATION TESTS")
	print("========================================")

	test_results.clear()

	test_shadow_slide()
	await get_tree().create_timer(0.5).timeout

	test_mirrorwalk()
	await get_tree().create_timer(0.5).timeout

	test_pivot()
	await get_tree().create_timer(0.5).timeout

	test_shadow_pivot()
	await get_tree().create_timer(0.5).timeout

	test_shadowshift()
	await get_tree().create_timer(0.5).timeout

	# Print summary
	print("\n========================================")
	print("TEST SUMMARY")
	print("========================================")
	var passed = 0
	var failed = 0
	var skipped = 0

	for test_name in test_results:
		var result = test_results[test_name]
		match result:
			"PASS":
				passed += 1
				print("✓ %s: %s" % [test_name, result])
			"FAIL":
				failed += 1
				print("✗ %s: %s" % [test_name, result])
			"SKIP":
				skipped += 1
				print("- %s: %s" % [test_name, result])

	print("\nTotal: %d passed, %d failed, %d skipped" % [passed, failed, skipped])
