extends Node3D

# Weapon sway settings
@export var sway_amount: float = 0.02
@export var sway_speed: float = 3.0
@export var sway_recovery_speed: float = 6.0

# Bob settings (movement animation)
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.08

# Attack settings
@export var attack_speed: float = 0.4
@export var attack_range: float = 2.5
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 0.5

# Animation positions
@export var idle_position: Vector3 = Vector3(0.4, -0.3, -0.5)
@export var attack_windup_position: Vector3 = Vector3(0.5, -0.1, -0.3)
@export var attack_swing_position: Vector3 = Vector3(0.2, -0.4, -0.7)
@export var attack_windup_rotation: Vector3 = Vector3(0, -30, -20)
@export var attack_swing_rotation: Vector3 = Vector3(-45, 20, 10)

# References
var player: CharacterBody3D
var camera: Camera3D
var crowbar_model: Node3D

# State tracking
var time: float = 0.0
var default_position: Vector3
var default_rotation: Vector3
var is_attacking: bool = false
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var mouse_movement: Vector2 = Vector2.ZERO

func _ready():
	# Store the default position and rotation
	default_position = idle_position
	default_rotation = Vector3.ZERO
	position = default_position
	
	# Find references
	if get_parent():
		camera = get_parent() as Camera3D
		if camera and camera.get_parent() and camera.get_parent().get_parent():
			player = camera.get_parent().get_parent()
			if player is CharacterBody3D:
				print("Crowbar: Found player and camera")
			else:
				player = null
				push_warning("Crowbar: Could not find player")
	
	# Find the crowbar model (should be a child)
	for child in get_children():
		if child.name == "Crowbar":
			crowbar_model = child
			break

func _process(delta):
	time += delta
	
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Handle attack animation
	if is_attacking:
		process_attack(delta)
	else:
		# Handle weapon sway from mouse movement
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			apply_sway(delta)
		
		# Handle weapon bob from movement
		if player:
			apply_bob(delta)
	
	# Check for attack input
	if Input.is_action_just_pressed("ui_select") and not is_attacking and cooldown_timer <= 0:
		start_attack()

func start_attack():
	is_attacking = true
	attack_timer = 0.0
	cooldown_timer = attack_cooldown

func process_attack(delta):
	attack_timer += delta
	
	var attack_progress = attack_timer / attack_speed
	
	if attack_progress < 0.3:  # Windup phase
		var windup_progress = attack_progress / 0.3
		position = default_position.lerp(attack_windup_position, windup_progress)
		rotation_degrees = default_rotation.lerp(attack_windup_rotation, windup_progress)
		
	elif attack_progress < 0.7:  # Swing phase
		var swing_progress = (attack_progress - 0.3) / 0.4
		position = attack_windup_position.lerp(attack_swing_position, swing_progress)
		rotation_degrees = attack_windup_rotation.lerp(attack_swing_rotation, swing_progress)
		
		# Check for hit at the midpoint of the swing
		if attack_progress >= 0.5 and attack_progress < 0.52:
			check_hit()
			
	else:  # Recovery phase
		var recovery_progress = (attack_progress - 0.7) / 0.3
		position = attack_swing_position.lerp(default_position, recovery_progress)
		rotation_degrees = attack_swing_rotation.lerp(default_rotation, recovery_progress)
		
		if attack_progress >= 1.0:
			is_attacking = false

func check_hit():
	if not camera:
		return
	
	# Perform raycast from camera center
	var space_state = camera.get_world_3d().direct_space_state
	var origin = camera.global_position
	var end = origin - camera.global_transform.basis.z * attack_range
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [player]  # Exclude the player from hits
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Hit: ", result.collider.name)
		# Add hit effects, damage, etc. here
		apply_hit_effect(result.collider, result.position)

func apply_hit_effect(target, hit_position):
	# Apply damage if the target has a health component
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	# You can add particle effects, sound effects, etc. here
	print("Applied ", attack_damage, " damage to ", target.name)

func apply_sway(delta):
	if is_attacking:
		return
	
	# Smoothly decay the mouse movement
	mouse_movement = mouse_movement.lerp(Vector2.ZERO, sway_recovery_speed * delta)

func apply_bob(delta):
	if is_attacking or not player:
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
		if not is_attacking:
			# Apply sway based on mouse movement
			mouse_movement = event.relative
			
			# Calculate sway
			var sway_x = -mouse_movement.x * sway_amount * 0.001
			var sway_y = mouse_movement.y * sway_amount * 0.001
			
			# Apply sway with limits
			position.x = clamp(default_position.x + sway_x, default_position.x - 0.1, default_position.x + 0.1)
			position.y = clamp(default_position.y + sway_y, default_position.y - 0.1, default_position.y + 0.1)
