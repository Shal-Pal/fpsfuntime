extends Control

# Crosshair settings
@export var min_spread: float = 8.0  # Minimum distance from center when still
@export var max_spread: float = 25.0  # Maximum distance from center when moving
@export var bloom_speed: float = 15.0  # How fast it blooms
@export var reset_speed: float = 8.0  # How fast it returns to center

# Current spread
var current_spread: float = min_spread

# References to crosshair elements
@onready var top = $Center/Top
@onready var bottom = $Center/Bottom
@onready var left = $Center/Left
@onready var right = $Center/Right

# Reference to player (will be set from main scene)
var player: CharacterBody3D

func _ready():
	# Try to find player in the scene - wait a bit for scene to load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Try multiple methods to find the player
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Try finding by type
		player = get_tree().root.find_child("Player", true, false)
	
	if not player:
		# Try finding any CharacterBody3D
		for node in get_tree().root.get_children():
			var found = _find_character_body(node)
			if found:
				player = found
				break
	
	if player:
		print("Crosshair: Found player at ", player.get_path())
	else:
		push_warning("Crosshair: Player not found! Bloom effect won't work.")

func _find_character_body(node: Node) -> CharacterBody3D:
	if node is CharacterBody3D:
		return node
	for child in node.get_children():
		var result = _find_character_body(child)
		if result:
			return result
	return null

func _process(delta):
	if not player:
		return
	
	# Calculate player movement (horizontal velocity)
	var velocity_2d = Vector2(player.velocity.x, player.velocity.z)
	var speed = velocity_2d.length()
	
	# Target spread based on movement
	var target_spread = min_spread
	if speed > 0.1:  # If moving
		# Increase spread based on speed (normalized to max movement speed)
		var speed_ratio = clamp(speed / 10.0, 0.0, 1.0)
		target_spread = lerp(min_spread, max_spread, speed_ratio)
	
	# Smoothly interpolate to target spread
	if current_spread < target_spread:
		current_spread = move_toward(current_spread, target_spread, bloom_speed * delta)
	else:
		current_spread = move_toward(current_spread, target_spread, reset_speed * delta)
	
	# Update crosshair positions
	update_crosshair_positions()

func update_crosshair_positions():
	# Top line
	top.offset_top = -current_spread - 12.0
	top.offset_bottom = -current_spread
	
	# Bottom line
	bottom.offset_top = current_spread
	bottom.offset_bottom = current_spread + 12.0
	
	# Left line
	left.offset_left = -current_spread - 12.0
	left.offset_right = -current_spread
	
	# Right line
	right.offset_left = current_spread
	right.offset_right = current_spread + 12.0
