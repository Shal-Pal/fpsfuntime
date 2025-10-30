extends Node3D

# Weapon sway settings
@export var sway_amount: float = 0.02
@export var sway_speed: float = 3.0
@export var sway_recovery_speed: float = 6.0

# Bob settings (movement animation)
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.08

# Reference to the player for movement detection
var player: CharacterBody3D
var camera: Camera3D
var time: float = 0.0
var default_position: Vector3
var mouse_movement: Vector2 = Vector2.ZERO

func _ready():
	# Store the default position
	default_position = position
	
	# Find the camera (parent)
	if get_parent() is Camera3D:
		camera = get_parent()
		
		# Find the player node (Camera -> Head -> Player)
		if camera.get_parent() and camera.get_parent().get_parent():
			player = camera.get_parent().get_parent()
			if player is CharacterBody3D:
				print("WeaponHolder: Found player and camera")
			else:
				player = null
				push_warning("WeaponHolder: Could not find player CharacterBody3D")

func _process(delta):
	time += delta
	
	# Handle weapon sway from mouse movement
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		apply_sway(delta)
	
	# Handle weapon bob from movement
	if player:
		apply_bob(delta)

func apply_sway(delta):
	# Smoothly return to center when not moving mouse
	mouse_movement = mouse_movement.lerp(Vector2.ZERO, sway_recovery_speed * delta)

func apply_bob(delta):
	if not player:
		return
		
	# Calculate player movement speed
	var velocity_2d = Vector2(player.velocity.x, player.velocity.z)
	var speed = velocity_2d.length()
	
	# Apply bobbing effect when moving
	if speed > 0.1:
		# Vertical bob
		var bob_offset_y = sin(time * bob_frequency) * bob_amplitude * (speed / 5.0)
		# Horizontal bob (smaller, offset by 90 degrees)
		var bob_offset_x = cos(time * bob_frequency * 2.0) * bob_amplitude * 0.3 * (speed / 5.0)
		
		# Apply the bob
		position.y = default_position.y + bob_offset_y
		position.x = default_position.x + bob_offset_x
	else:
		# Return to default position when not moving
		position = position.lerp(default_position, sway_recovery_speed * delta)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Store mouse movement for sway
		mouse_movement = event.relative
		
		# Calculate sway
		var sway_x = -mouse_movement.x * sway_amount * 0.001
		var sway_y = mouse_movement.y * sway_amount * 0.001
		
		# Apply sway with limits
		position.x = clamp(default_position.x + sway_x, default_position.x - 0.1, default_position.x + 0.1)
		position.y = clamp(default_position.y + sway_y, default_position.y - 0.1, default_position.y + 0.1)
