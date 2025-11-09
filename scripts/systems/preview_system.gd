# res://scripts/systems/preview_system.gd
extends Node

# === SCRIPT REFERENCES FOR STATIC FUNCTIONS ===
var gs = load("res://scripts/systems/grid_system.gd")

# === PREVIEW NODES ===
var preview_container: Node2D = null
var active_ghosts: Array[Node2D] = []
var active_previews: Array[Node2D] = []

func _ready() -> void:
	"""Initialize preview system."""
	# Create container for previews if it doesn't exist
	if not preview_container:
		preview_container = Node2D.new()
		preview_container.name = "PreviewContainer"
		add_child(preview_container)

# === GHOST CREATION ===
func create_ghost(source: Node2D) -> Node2D:
	"""
	Create a semi-transparent ghost sprite from a source node.

	Args:
		source: The node to create a ghost from

	Returns:
		The ghost node (Sprite2D)
	"""
	if not source:
		return null

	# Create ghost sprite
	var ghost = Sprite2D.new()
	ghost.name = source.name + "_Ghost"

	# Copy sprite properties if source has a sprite
	if source is Sprite2D:
		ghost.texture = source.texture
		ghost.offset = source.offset
		ghost.scale = source.scale
		ghost.rotation = source.rotation
	elif source.has_node("Sprite2D"):
		var source_sprite = source.get_node("Sprite2D")
		ghost.texture = source_sprite.texture
		ghost.offset = source_sprite.offset
		ghost.scale = source_sprite.scale
		ghost.rotation = source_sprite.rotation

	# Set position
	ghost.position = source.position

	# Make semi-transparent
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.5)

	# Add to preview container
	if preview_container:
		preview_container.add_child(ghost)

	active_ghosts.append(ghost)
	return ghost

# === GHOST POSITIONING ===
func update_ghost_position(ghost: Node2D, target_pos: Vector2) -> void:
	"""
	Update ghost position and apply color coding.

	Args:
		ghost: The ghost node to update
		target_pos: Target world position
	"""
	if not ghost:
		return

	# Smoothly interpolate to target (for visual feedback)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "position", target_pos, 0.3)

func set_ghost_valid(ghost: Node2D, valid: bool) -> void:
	"""
	Set ghost color to indicate validity.

	Args:
		ghost: The ghost node
		valid: true for valid (green), false for invalid (red)
	"""
	if not ghost:
		return

	if valid:
		# Green: Valid transformation
		ghost.modulate = Color(0.0, 1.0, 0.0, 0.5)
	else:
		# Red: Invalid transformation
		ghost.modulate = Color(1.0, 0.0, 0.0, 0.5)

# === PREVIEW CLEARING ===
func clear_all_previews() -> void:
	"""Remove all ghost and preview nodes."""
	# Clear ghosts
	for ghost in active_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	active_ghosts.clear()

	# Clear other previews
	for preview in active_previews:
		if is_instance_valid(preview):
			preview.queue_free()
	active_previews.clear()

# === TRANSFORMATION TRAIL PREVIEWS ===
func show_shadow_slide_preview(from_pos: Vector2i, to_pos: Vector2i) -> void:
	"""
	Show preview for Shadow Slide (dotted line path).

	Args:
		from_pos: Starting tile position
		to_pos: Ending tile position
	"""
	var from_world = gs.tile_to_world(from_pos)
	var to_world = gs.tile_to_world(to_pos)

	# Create dotted line preview
	var line = Line2D.new()
	line.name = "ShadowSlidePath"
	line.add_point(from_world)
	line.add_point(to_world)
	line.default_color = Color(0.6, 0.2, 0.7, 0.7)  # Purple
	line.width = 2.0

	if preview_container:
		preview_container.add_child(line)
	active_previews.append(line)

	# Create ghost at destination
	var ghost = Sprite2D.new()
	ghost.name = "ShadowSlideGhost"
	ghost.position = to_world
	ghost.modulate = Color(0.6, 0.2, 0.7, 0.3)  # Purple semi-transparent
	if preview_container:
		preview_container.add_child(ghost)
	active_previews.append(ghost)

func show_mirrorwalk_preview(mirror_start: Vector2, mirror_end: Vector2, reflected_pos: Vector2) -> void:
	"""
	Show preview for Mirrorwalk (mirror line and reflection).

	Args:
		mirror_start: Mirror line start point
		mirror_end: Mirror line end point
		reflected_pos: Reflected position
	"""
	# Draw mirror line
	var mirror_line = Line2D.new()
	mirror_line.name = "MirrorLine"
	mirror_line.add_point(mirror_start)
	mirror_line.add_point(mirror_end)
	mirror_line.default_color = Color(0.0, 0.75, 0.83, 0.8)  # Cyan
	mirror_line.width = 3.0

	if preview_container:
		preview_container.add_child(mirror_line)
	active_previews.append(mirror_line)

	# Draw reflection path (dotted line)
	var reflection_path = Line2D.new()
	reflection_path.name = "ReflectionPath"
	# Get approximate current position (would need to be passed in real implementation)
	reflection_path.default_color = Color(0.0, 0.75, 0.83, 0.5)  # Cyan semi-transparent
	reflection_path.width = 1.5

	if preview_container:
		preview_container.add_child(reflection_path)
	active_previews.append(reflection_path)

	# Create ghost at reflected position
	var ghost = Sprite2D.new()
	ghost.name = "MirrorwalkGhost"
	ghost.position = reflected_pos
	ghost.modulate = Color(0.0, 0.75, 0.83, 0.3)  # Cyan semi-transparent
	if preview_container:
		preview_container.add_child(ghost)
	active_previews.append(ghost)

func show_pivot_preview(pivot_point: Vector2, angle_degrees: float, clockwise: bool) -> void:
	"""
	Show preview for Pivot (rotation arc).

	Args:
		pivot_point: Center of rotation
		angle_degrees: Rotation angle
		clockwise: Rotation direction
	"""
	# Draw rotation arc
	var arc = Node2D.new()
	arc.name = "PivotArc"

	# Create arc using line points
	var radius: float = 40.0
	var start_angle: float = 0.0  # Assuming facing right initially
	var end_angle: float = start_angle + (angle_degrees if clockwise else -angle_degrees)

	var arc_points: PackedVector2Array = []
	var steps: int = int(abs(angle_degrees) / 5.0)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var angle_rad: float = deg_to_rad(start_angle + (end_angle - start_angle) * t)
		var x: float = pivot_point.x + cos(angle_rad) * radius
		var y: float = pivot_point.y + sin(angle_rad) * radius
		arc_points.append(Vector2(x, y))

	var arc_line = Line2D.new()
	arc_line.points = arc_points
	arc_line.default_color = Color(1.0, 0.65, 0.15, 0.7)  # Amber
	arc_line.width = 2.0

	arc.add_child(arc_line)

	if preview_container:
		preview_container.add_child(arc)
	active_previews.append(arc)

func show_shadow_pivot_preview(anchor_point: Vector2, tether_start: Vector2, rotation_arc_points: PackedVector2Array) -> void:
	"""
	Show preview for Shadow Pivot (anchor, tether, arc).

	Args:
		anchor_point: Center of rotation
		tether_start: Where tether line starts
		rotation_arc_points: Points defining rotation arc
	"""
	# Draw anchor point indicator
	var _anchor = CircleShape2D.new()
	var anchor_visual = Node2D.new()
	anchor_visual.name = "AnchorPoint"
	anchor_visual.position = anchor_point

	# Create visual indicator (circle)
	var anchor_circle = CircleShape2D.new()
	anchor_circle.radius = 6.0

	if preview_container:
		preview_container.add_child(anchor_visual)
	active_previews.append(anchor_visual)

	# Draw tether line
	var tether_line = Line2D.new()
	tether_line.name = "TetherLine"
	tether_line.add_point(tether_start)
	tether_line.add_point(anchor_point)
	tether_line.default_color = Color(1.0, 0.65, 0.15, 0.7)  # Amber
	tether_line.width = 2.0

	if preview_container:
		preview_container.add_child(tether_line)
	active_previews.append(tether_line)

	# Draw rotation arc
	if rotation_arc_points.size() > 0:
		var arc_line = Line2D.new()
		arc_line.name = "RotationArc"
		arc_line.points = rotation_arc_points
		arc_line.default_color = Color(1.0, 0.65, 0.15, 0.5)  # Amber semi-transparent
		arc_line.width = 2.0

		if preview_container:
			preview_container.add_child(arc_line)
		active_previews.append(arc_line)

func show_shadowshift_preview(center_point: Vector2, scale_factor: float, ghost: Node2D) -> void:
	"""
	Show preview for Shadowshift (scaled ghost).

	Args:
		center_point: Center of dilation
		scale_factor: Scale multiplier
		ghost: Ghost node to scale
	"""
	if not ghost:
		return

	# Apply scale to ghost
	ghost.scale = Vector2(scale_factor, scale_factor)
	ghost.modulate = Color(0.6, 0.2, 0.7, 0.3)  # Violet semi-transparent

	# Draw center point indicator
	var center_circle = CircleShape2D.new()
	center_circle.radius = 4.0

	if preview_container:
		preview_container.add_child(ghost)
	active_previews.append(ghost)

	# Draw dilation lines (from center to corners of scaled object)
	if ghost.has_node("Sprite2D"):
		var sprite = ghost.get_node("Sprite2D")
		var half_width: float = sprite.get_rect().size.x / 2.0 * scale_factor
		var half_height: float = sprite.get_rect().size.y / 2.0 * scale_factor

		var corners = [
			Vector2(-half_width, -half_height),
			Vector2(half_width, -half_height),
			Vector2(half_width, half_height),
			Vector2(-half_width, half_height)
		]

		for corner in corners:
			var line = Line2D.new()
			line.add_point(center_point)
			line.add_point(center_point + corner)
			line.default_color = Color(0.6, 0.2, 0.7, 0.4)  # Violet
			line.width = 1.0

			if preview_container:
				preview_container.add_child(line)
			active_previews.append(line)

# === UTILITY ===
func has_active_previews() -> bool:
	"""Check if there are active previews."""
	return active_ghosts.size() > 0 or active_previews.size() > 0
