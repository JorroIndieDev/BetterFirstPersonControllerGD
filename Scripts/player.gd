'''
--------------------------------------------------------------------------------
################	First Person Controller 	################################
--------------------------------------------------------------------------------
	9/28/2024 - Jorro total linhas: 231
	
	vars used in project on @export Gravity = 17 Jump_Velocity = 8
	
To do:
	values multiplied by delta need to be changed for @export vars
	same with other values that can be multiplied by delta
	organize the code before any other feature
	clean the code (remove repeats) #HASDEBUG-tag for debug screen vars
	make the code flexible with other scenes
	
	after the above implement features
	-!! raycast gravity check GROUNDCHECK
	-crouch
	-slide
	-step climp
	-wall jump
	-ramp movement
	for now this is all
'''


extends CharacterBody3D

# HUD
@onready var debug_screen = $Head/Camera3D/debug_screen
@onready var debug_speed = $Head/Camera3D/debug_screen/Speed
@onready var debug_velocity = $Head/Camera3D/debug_screen/Velocity
@onready var debug_FOV = $Head/Camera3D/debug_screen/FOV
@onready var debug_flex1 = $Head/Camera3D/debug_screen/FLEX1
@onready var debug_flex2 = $Head/Camera3D/debug_screen/FLEX2
@onready var debug_flex3 = $Head/Camera3D/debug_screen/FLEX3
@onready var debug_flex4 = $Head/Camera3D/debug_screen/FLEX4

@onready var settings_menu = $Head/Camera3D/Settings
@onready var gravity_setting = $Head/Camera3D/Settings/Gravity/LineEdit
@onready var jump_setting = $Head/Camera3D/Settings/JumpHight/LineEdit2
@onready var speed_setting = $Head/Camera3D/Settings/Speed/LineEdit3
@onready var sprint_setting = $Head/Camera3D/Settings/SprintSPeed/LineEdit4
@onready var flex3_setting = $Head/Camera3D/Settings/Flex3

var _basis = Basis()

# Movement Vars
var current_speed = 0 
var SPRINTING_SPEED = 9.0
var WALKING_SPEED = 6.0

@export var gravity :float # 16
@onready var ground_check = $GroundCheck
var fall_contact = false

# Jump Vars
@onready var can_jump = true
@export var jump_delay :float # 0.25
@export var jump_velocity :float # 6
@onready var coyote_jump :bool = true

# Head bobing
const BOB_FQ = 2
const BOB_AMP = 0.1
var t_bob = 0.0

# Camera FOV
var BASE_FOV = 75.0
const FOV_CHANGE = 1.5
var velocity_clamped
var target_fov

# Camera vars
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var original_camera_pos :Vector3 = camera.transform.origin
var camera_rotation = Vector3.ZERO
var mouse_sense = 0.06
var look_rot = Vector3.ZERO
var move_dir = Vector3.ZERO
var fov_change_enable = true
var tilt_axis = Vector3()
var tilt_angle = deg_to_rad(45)
var tilt_amount = deg_to_rad(15.0) # Adjust this value to control the tilt amount


func _ready():
	current_speed = WALKING_SPEED
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gravity_setting.placeholder_text = str(gravity)
	jump_setting.placeholder_text = str(jump_velocity)
	speed_setting.placeholder_text = str(WALKING_SPEED)
	sprint_setting.placeholder_text = str(SPRINTING_SPEED)

	settings_menu.connect("gravity_setting_change",ChangeGravity)
	settings_menu.connect("jump_setting_change",ChangeJump)
	settings_menu.connect("speed_setting_change",ChangeSpeed)
	settings_menu.connect("sprint_speed_setting_change",ChangeSprintSpeed)
	


func _input(event):

	if event is InputEventMouseMotion and  Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_rot.y -= (event.relative.x * mouse_sense)
		look_rot.x -= (event.relative.y * mouse_sense)
		look_rot.x = clamp(look_rot.x, -80, 80)


	if Input.is_action_just_pressed("ESC"):
		debug_screen.visible = !debug_screen.visible
		settings_menu.visible = !settings_menu.visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) if settings_menu.visible else Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):


	# Head Rotation
	head.rotation_degrees.x = look_rot.x
	rotation_degrees.y = look_rot.y


	# Movement CHANGE
	var direction = Vector3(Input.get_axis("Left", "Right"), 0, Input.get_axis("Forward", "Backwards")).normalized().rotated(Vector3.UP, rotation.y)
	debug_flex2.text = str(direction)

	# Sprint
	if Input.is_action_pressed("Sprint"):
		current_speed = lerp(current_speed, SPRINTING_SPEED, delta * 5.0)
	else:
		current_speed = lerp(current_speed, WALKING_SPEED, delta * 5.0)


	# Gravity
	if not is_on_floor():
		coyoteTime()


	# Jump Variable
	var is_jumping :bool = Input.is_action_pressed("Jump") and coyote_jump and can_jump
	
	# Jump
	if is_on_floor() and is_jumping:
		velocity.y = 0
		velocity.y = jump_velocity
		can_jump = false
		reset_jump()
	
	
	# Grounded #HASDEBUG
	if is_on_floor():
		coyote_jump = true
		debug_flex1.text = "null"
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = lerp(velocity.x, direction.x * current_speed, delta * 6.7)
			velocity.z = lerp(velocity.z, direction.z * current_speed, delta * 6.7)
	
	# Not Grounded
	else:
		velocity.y -= gravity * delta
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * 3.0)


	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	
	if velocity != Vector3.ZERO:
		camera.transform.origin = lerp(camera.transform.origin,_headbob(t_bob),delta * 5.0)
	else:
		camera.transform.origin = lerp(camera.transform.origin,original_camera_pos,delta * 5.0)


	# FOV
	velocity_clamped = clamp(velocity.length(), 0.5, SPRINTING_SPEED * 2)
	target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 5.0) if velocity_clamped >= 7 else lerp(camera.fov, BASE_FOV, delta * 5.0)


	# Head tilt #HASDEBUG
	tilt_axis = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	camera.rotation_degrees.z = clamp(camera.rotation_degrees.z + tilt_axis * tilt_amount, -tilt_angle, tilt_angle)
	camera_rotation = camera.rotation_degrees.z
	debug_flex3.text = str(camera.rotation_degrees.z) + " tilt"

	# Reset camera rotation if no movement keys are pressed
	if tilt_axis == 0:
		debug_flex3.text = str(camera.rotation_degrees.z) + " stopped moving"
		camera.rotation_degrees.z = lerp(camera_rotation,0.0,delta * 15)  # Reset rotation to zero


	# HUD Info #HASDEBUG
	debug_speed.text = "speed: " + str(current_speed)
	debug_velocity.text = "velocity: " + str(velocity)
	debug_FOV.text = "FOV: " + str(camera.fov)


	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FQ) * BOB_AMP
	pos.x = sin(time * BOB_FQ/2) * BOB_AMP
	return pos


func reset_jump():
	can_jump = true


func coyoteTime(): #HASDEBUG
	await get_tree().create_timer(.1).timeout
	debug_flex1.text = "COYOTE"
	coyote_jump = false


func ChangeGravity(value):
	gravity = value


func ChangeJump(value):
	jump_velocity = value


func ChangeSpeed(value):
	WALKING_SPEED = value


func ChangeSprintSpeed(value):
	SPRINTING_SPEED = value
