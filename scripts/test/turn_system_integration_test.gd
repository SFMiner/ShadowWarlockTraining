# res://scripts/test/turn_system_integration_test.gd
extends Node

var player: Node2D = null
var enemies: Array[Node2D] = []
var turn_count: int = 0

func _ready() -> void:
	"""Initialize turn system integration test."""
	print("=== TURN SYSTEM INTEGRATION TEST ===")

	# Get player and enemies
	player = get_tree().get_first_child_in_group("player")
	enemies = get_tree().get_nodes_in_group("enemies")

	if not player:
		push_error("Player not found!")
		return

	print("Player: %s" % player.name)
	print("Enemies: %d" % enemies.size())

	# Report enemy types
	for enemy in enemies:
		if enemy is Enemy:
			print("  - %s (%s)" % [enemy.name, enemy.enemy_type])

	# Register systems
	if TurnManager:
		TurnManager.set_player(player)
		for enemy in enemies:
			TurnManager.register_enemy(enemy)

	# Connect signals
	if TurnManager:
		TurnManager.level_won.connect(_on_level_won)
		TurnManager.level_lost.connect(_on_level_lost)
		TurnManager.turn_started.connect(_on_turn_started)
		TurnManager.turn_completed.connect(_on_turn_completed)

	# Connect enemy signals
	for enemy in enemies:
		if enemy is Enemy:
			enemy.action_planned.connect(_on_enemy_action_planned.bindv([enemy]))
			enemy.enemy_defeated.connect(_on_enemy_defeated)

	# Start turn cycle
	await get_tree().create_timer(1.0).timeout
	start_test()

func start_test() -> void:
	"""Start the turn system test cycle."""
	print("\nStarting turn cycle...")

	if TurnManager:
		TurnManager.start_turn()

func _on_turn_started() -> void:
	"""Handle turn start."""
	turn_count += 1
	print("\n--- TURN %d STARTED ---" % turn_count)

func _on_turn_completed() -> void:
	"""Handle turn completion."""
	print("--- TURN %d COMPLETE ---\n" % turn_count)

func _on_enemy_action_planned(enemy: Node2D) -> void:
	"""Report enemy action."""
	if enemy is Enemy:
		var action_type = enemy.telegraph_data.get("action_type", "unknown")
		print("  [%s] Plans action: %s" % [enemy.name, action_type])

func _on_enemy_defeated(enemy: Node2D) -> void:
	"""Report enemy defeat."""
	print("  [%s] DEFEATED!" % enemy.name)

func _on_level_won() -> void:
	"""Handle level win."""
	print("\n*** LEVEL WON - ALL ENEMIES DEFEATED ***\n")

func _on_level_lost() -> void:
	"""Handle level loss."""
	print("\n*** LEVEL LOST - PLAYER DEFEATED ***\n")
