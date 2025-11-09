# res://scripts/autoload/save_system.gd
extends Node

# === CONSTANTS ===
const SAVE_KEY: String = "shadow_warlock_save_v1"
const FALLBACK_KEY: String = "shadow_warlock_fallback"
const SAVE_VERSION: String = "1.0"

# === JAVASCRIPT INTERFACE ===
var js_interface: Variant = null

func _ready() -> void:
	"""Initialize JavaScript bridge for browser localStorage."""
	if OS.has_feature("web"):
		js_interface = JavaScriptBridge.get_interface("localStorage")
	else:
		# Fallback to file-based save system on desktop
		pass

# === SAVE FUNCTIONS ===
func save_game(data: Dictionary) -> bool:
	"""
	Save game state to browser localStorage or local file.

	Args:
		data: Dictionary containing all game state to save

	Returns:
		true if save successful, false otherwise
	"""
	if not data:
		push_error("SaveSystem: Cannot save empty data")
		return false

	# Add metadata
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"data": data
	}

	if OS.has_feature("web"):
		return _save_to_localstorage(save_data)
	else:
		return _save_to_file(save_data)

func _save_to_localstorage(save_data: Dictionary) -> bool:
	"""Save to browser localStorage via JavaScriptBridge."""
	if not js_interface:
		push_error("SaveSystem: JavaScript interface not available")
		return false

	var json_string: String = JSON.stringify(save_data)
	if json_string.is_empty():
		push_error("SaveSystem: Failed to stringify save data")
		return false

	js_interface.setItem(SAVE_KEY, json_string)
	return true

func _save_to_file(save_data: Dictionary) -> bool:
	"""Fallback: Save to local file (desktop)."""
	var file := FileAccess.open("user://shadow_warlock_save.json", FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: Failed to open file for writing")
		return false

	var json_string: String = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	return true

# === LOAD FUNCTIONS ===
func load_game() -> Dictionary:
	"""
	Load game state from browser localStorage or local file.

	Returns:
		Dictionary with game data, or empty dict if no save exists
	"""
	if OS.has_feature("web"):
		return _load_from_localstorage()
	else:
		return _load_from_file()

func _load_from_localstorage() -> Dictionary:
	"""Load from browser localStorage via JavaScriptBridge."""
	if not js_interface:
		push_warning("SaveSystem: JavaScript interface not available, returning empty data")
		return {}

	var json_string: String = js_interface.getItem(SAVE_KEY)
	if not json_string or json_string.is_empty():
		return {}

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SaveSystem: Failed to parse localStorage data")
		return {}

	var save_data: Dictionary = json.data
	if _validate_save_data(save_data):
		return save_data.get("data", {})
	else:
		push_warning("SaveSystem: Save data validation failed")
		return {}

func _load_from_file() -> Dictionary:
	"""Fallback: Load from local file (desktop)."""
	if not FileAccess.file_exists("user://shadow_warlock_save.json"):
		return {}

	var file := FileAccess.open("user://shadow_warlock_save.json", FileAccess.READ)
	if not file:
		push_error("SaveSystem: Failed to open save file for reading")
		return {}

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("SaveSystem: Failed to parse save file")
		return {}

	var save_data: Dictionary = json.data
	if _validate_save_data(save_data):
		return save_data.get("data", {})
	else:
		push_warning("SaveSystem: Save file validation failed")
		return {}

# === DELETE FUNCTIONS ===
func delete_save() -> void:
	"""Delete saved game data."""
	if OS.has_feature("web"):
		_delete_from_localstorage()
	else:
		_delete_from_file()

func _delete_from_localstorage() -> void:
	"""Delete from browser localStorage."""
	if not js_interface:
		push_warning("SaveSystem: Cannot delete - JavaScript interface not available")
		return

	js_interface.removeItem(SAVE_KEY)

func _delete_from_file() -> void:
	"""Fallback: Delete local file."""
	if FileAccess.file_exists("user://shadow_warlock_save.json"):
		DirAccess.remove_absolute("user://shadow_warlock_save.json")

# === CHECK FUNCTIONS ===
func has_save() -> bool:
	"""Check if a save file exists."""
	if OS.has_feature("web"):
		return _has_localstorage_save()
	else:
		return _has_file_save()

func _has_localstorage_save() -> bool:
	"""Check if localStorage save exists."""
	if not js_interface:
		return false

	var json_string: String = js_interface.getItem(SAVE_KEY)
	return json_string != null and not json_string.is_empty()

func _has_file_save() -> bool:
	"""Check if file save exists."""
	return FileAccess.file_exists("user://shadow_warlock_save.json")

# === VALIDATION ===
func _validate_save_data(save_data: Dictionary) -> bool:
	"""
	Validate save data structure.

	Args:
		save_data: Save data to validate

	Returns:
		true if valid, false otherwise
	"""
	if not save_data.has("version"):
		push_warning("SaveSystem: Save missing version field")
		return false

	if not save_data.has("timestamp"):
		push_warning("SaveSystem: Save missing timestamp field")
		return false

	if not save_data.has("data"):
		push_warning("SaveSystem: Save missing data field")
		return false

	# Check version compatibility
	if save_data["version"] != SAVE_VERSION:
		push_warning("SaveSystem: Save version mismatch (expected %s, got %s)" % [SAVE_VERSION, save_data["version"]])
		# For now, we'll still accept it - versioning for future updates

	return true

# === UTILITY FUNCTIONS ===
func get_save_info() -> Dictionary:
	"""Get metadata about the current save."""
	if OS.has_feature("web"):
		return _get_localstorage_info()
	else:
		return _get_file_info()

func _get_localstorage_info() -> Dictionary:
	"""Get metadata from localStorage save."""
	if not js_interface or not has_save():
		return {}

	var json_string: String = js_interface.getItem(SAVE_KEY)
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		return {}

	var save_data: Dictionary = json.data
	return {
		"exists": true,
		"version": save_data.get("version", "unknown"),
		"timestamp": save_data.get("timestamp", "unknown"),
		"location": "localStorage"
	}

func _get_file_info() -> Dictionary:
	"""Get metadata from file save."""
	if not has_save():
		return {}

	var file := FileAccess.open("user://shadow_warlock_save.json", FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		return {}

	var save_data: Dictionary = json.data
	return {
		"exists": true,
		"version": save_data.get("version", "unknown"),
		"timestamp": save_data.get("timestamp", "unknown"),
		"location": "user://shadow_warlock_save.json"
	}
