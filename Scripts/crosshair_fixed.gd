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
	# Set initial spread
	current_spread = min_spread
	
	# Try to find player in the scene after a brief delay
	call_deferred("find_player")

func find_player():
	# Try multiple methods to find the player
	
	# Method 1: Look for nodes in "player" group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Crosshair: Found player via group")
		return
	
	# Method 2: Search by name
	var root = get_tree().root
	player = root.find_child("Player", true, false)
	if player:
		print("Crosshair: Found player by name")
		return
	
	# Method 3: Search for any CharacterBody3D
	player = find_node_by_class(root, "CharacterBody3D")
	if player:
		print("Crosshair: Found player by class")
		return
	
	push_warning("Crosshair: Could not find player! Bloom effect won't work.")

func find_node_by_class(node: Node, class_name: String) -> Node:
	if node.get_class() == class_name:
		return node
	
	for child in node.get_children():
		var result = find_node_by_class(child, class_name)
		if result:
			return result
	
	return null

func _process(delta):
	if not player:
		# Try to find player again if we haven't found it yet
		find_player()
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
	if not top or not bottom or not left or not right:
		return
		
	# Top line
	top.position.y = -current_spread - 4.0
	
	# Bottom line
	bottom.position.y = current_spread + 4.0
	
	# Left line
	left.position.x = -current_spread - 4.0
	
	# Right line
	right.position.x = current_spread + 4.0
