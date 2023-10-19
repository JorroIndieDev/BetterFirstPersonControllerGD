'''
--------------------------------------------------------------------------------
################	First Person Controller 	################################
--------------------------------------------------------------------------------
	9/28/2024 - Jorro total linhas: 231
	
	vars used in project on @export Gravity = 22 Jump_Force = 6
	
To do:
	#HASDEBUG-tag for debug screen vars
	Still needs some more cleaning for the code and easier implementation of features
	
	after the above implement features
	-!! raycast gravity check GROUNDCHECK
	-ramp movement
	-step climp
	-wall jump / vaulting
	for now this is all
Currently doing:
	implementing slide / ramp movemnt and raycasts
	### leave feedback so i can keep improving this controller ###
Fixed:
	Sliding FIXED
	Crouch when under a ceiling FIXED
'''


extends CharacterBody3D

# HUD 
@onready var debug_screen = $Neck/Head/Camera3D/debug_screen
@onready var debug_speed = $Neck/Head/Camera3D/debug_screen/Speed
@onready var debug_velocity = $Neck/Head/Camera3D/debug_screen/Velocity
@onready var debug_FOV = $Neck/Head/Camera3D/debug_screen/FOV
@onready var debug_flex1 = $Neck/Head/Camera3D/debug_screen/FLEX1
@onready var debug_flex2 = $Neck/Head/Camera3D/debug_screen/FLEX2
@onready var debug_flex3 = $Neck/Head/Camera3D/debug_screen/FLEX3
@onready var debug_flex4 = $Neck/Head/Camera3D/debug_screen/FLEX4
@onready var settings_menu = $Neck/Head/Camera3D/Settings

@onready var gravity_setting = $Neck/Head/Camera3D/Settings/Gravity/LineEdit
@onready var jump_setting = $Neck/Head/Camera3D/Settings/JumpHight/LineEdit2
@onready var speed_setting = $Neck/Head/Camera3D/Settings/Speed/LineEdit3
@onready var sprint_setting = $Neck/Head/Camera3D/Settings/SprintSPeed/LineEdit4
@onready var flex3_setting = $Neck/Head/Camera3D/Settings/Flex3
# All @onready vars under #HUD are not needed for any movement of the character These vars only influence the GUI for debugging


var _basis = Basis() # just in case if it is needed eventually in the code


# Movement Vars
var current_speed :float = 0 
## Max sprinting speed set to 9.0 as default (float) 
@export var SPRINTING_SPEED :float = 9.0
## Max walking speed set to 6.0 as default (float)
@export var WALKING_SPEED :float = 6.0
## Gravity not set by the engine, [gravity] is set as 22 by default (float)
@export var gravity :float # 22
const ACCELERATION :float= 6.7
const FRICTION :float= 3.0


# Crouching vars
@export var crouching_mesh : MeshInstance3D
@export var crouching_collision : CollisionShape3D
@export var standing_mesh : MeshInstance3D
@export var standing_collision : CollisionShape3D
var is_crouching:bool


# Sliding vars
var is_sliding :bool
var slide_timer_max :float = 1.0
var slide_timer :float = 0.0
var slide_vector :Vector3 = Vector3.ZERO
var is_sprinting :bool = true
var sliding_speed :float = 10.0


# Jump Vars
@onready var can_jump = true
## Jumping heigh, default as 6.0 as default (float)
@export var jump_force :float # 6
@onready var coyote_jump :bool = true
## Ground Check is a RayCast3D node that slighly shows bellow the player collider and mesh
@export var ground_check : RayCast3D
## Ceiling Check is a RayCast3D node that slighly shows above the player collider and mesh
@export var ceiling_check : RayCast3D
var fall_contact :bool
var coyote_timer :float = 0.0
var coyote_time :float = 0.15
## Enable or disable double jumping
@export var double_jump_enable:bool = true
var slide_jump_boost :bool


# Head bobing
const BOB_FQ :int = 2
const BOB_AMP :float = 0.05
var t_bob :float = 0.0
@export var headbobbing :bool = true


# Camera FOV
## Fov change while moving faster
@export var fov_change_enable :bool = true
var BASE_FOV :float= 75.0
const FOV_CHANGE :float= 1.5
var velocity_clamped 
var target_fov :float
## Changing this value is not recomended, this value is multiplied by delta in every equasion related to the camera movement and the FOV change
@export var camera_delta_multiplier :float= 5.0


# Camera vars
## Takes a Node or Node2D as parent of the head Node3D Node
@export var neck: Node3D
## Takes a Node or Node2D as parent of a Camera3D Node
@export var head: Node3D
## Takes a Camera3D node
@export  var camera: Camera3D
@onready var original_head_pos :Vector3 = head.transform.origin
@onready var original_camera_pos :Vector3 = camera.transform.origin
@onready var crouching_head_pos = original_head_pos/10
## changing this value is not advised, if needed change very small quanteties (0.01)
@export var mouse_sense :float = 0.06
var camera_rotation  = Vector3.ZERO
var max_look_amount :float = 80
var look_rotation :Vector3 = Vector3.ZERO
var move_dir :Vector3 = Vector3.ZERO
## enable head leaning sideways when moving left or right
@export var head_leaning :bool = true
var tilt_axis = Vector3()
var tilt_angle = deg_to_rad(45)
var tilt_amount = deg_to_rad(0.5) 


func _ready():
	current_speed = WALKING_SPEED
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gravity_setting.placeholder_text = str(gravity)
	jump_setting.placeholder_text = str(jump_force)
	speed_setting.placeholder_text = str(WALKING_SPEED)
	sprint_setting.placeholder_text = str(SPRINTING_SPEED)

	settings_menu.connect("gravity_setting_change",ChangeGravity)
	settings_menu.connect("jump_setting_change",ChangeJump)
	settings_menu.connect("speed_setting_change",ChangeSpeed)
	settings_menu.connect("sprint_speed_setting_change",ChangeSprintSpeed)


func _input(event):

	if event is InputEventMouseMotion and  Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_rotation.y -= (event.relative.x * mouse_sense)
		look_rotation.x -= (event.relative.y * mouse_sense)
		look_rotation.x = clamp(look_rotation.x, -max_look_amount, max_look_amount)


	if Input.is_action_just_pressed("ESC"):
		debug_screen.visible = !debug_screen.visible
		settings_menu.visible = !settings_menu.visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) if (
			settings_menu.visible
			) else (
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				)


func _physics_process(delta):


	# Head Rotation
	head.rotation_degrees.x = look_rotation.x
	rotation_degrees.y = look_rotation.y

	# Jump Variable
	var is_jumping :bool = (
		Input.is_action_pressed("Jump") and can_jump 
		and !ceiling_check.is_colliding()
		)

	# Movement CHANGE
	var direction = Vector3(Input.get_axis("Left", "Right"),0,
	 Input.get_axis("Forward", "Backwards")).normalized().rotated(Vector3.UP, rotation.y)
	if direction and is_on_floor():
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * ACCELERATION)
	debug_flex2.text = str(direction) #not needed

	# Sprint
	if Input.is_action_pressed("Sprint"):
		current_speed = lerp(current_speed, SPRINTING_SPEED, delta * ACCELERATION)
		is_sprinting = true
	
		if direction != Vector3.ZERO and Input.is_action_just_pressed("Crouch"): # start slide
			slide_vector = direction
			is_sliding = true
			slide_timer = slide_timer_max
		elif !Input.is_action_pressed("Crouch"):
			is_sliding = false
			slide_timer = 0
	
	else:
		current_speed = lerp(current_speed, WALKING_SPEED, delta * ACCELERATION)
		is_sprinting = false


	# Crouching
	if Input.is_action_pressed("Crouch") and is_on_floor():
		is_crouching = true
		standing_mesh.visible = false
		standing_collision.disabled = true
		crouching_mesh.visible = true
		crouching_collision.disabled = false
	
	elif !Input.is_action_pressed("Crouch") and !ceiling_check.is_colliding() or !is_on_floor():
		standing_mesh.visible = true
		standing_collision.disabled = false
		crouching_mesh.visible = false
		crouching_collision.disabled = true
		
		current_speed = lerp(current_speed, WALKING_SPEED, delta * ACCELERATION)
		head.transform.origin = lerp(head.transform.origin,
		 original_head_pos,delta * camera_delta_multiplier*2)
		is_crouching = false
	
	if is_crouching:
		current_speed = lerp(current_speed, WALKING_SPEED/4, delta * ACCELERATION)
		head.transform.origin = lerp(head.transform.origin,
		 crouching_head_pos,delta * camera_delta_multiplier*2)
	elif is_sprinting and is_crouching:
		current_speed = lerp(current_speed, SPRINTING_SPEED/3, delta * ACCELERATION)

	# Sliding
	if is_sliding:
		slide_timer -= delta
#		direction = (transform.basis * Vector3(slide_vector.x,0,slide_vector.z)).normalized()
		current_speed = (slide_timer + 0.25) * sliding_speed

		if slide_timer <= 0:
			is_sliding = false


	# Jumping
	if is_on_floor():
		coyote_timer = 0.0
		can_jump = true
		slide_jump_boost = false
	else:
		coyote_timer += delta
		velocity.y -= gravity * delta
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * (ACCELERATION/2))
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * (ACCELERATION/2))
	
	if is_jumping and coyote_timer < coyote_time:
		if is_sliding:
			velocity.y = jump_force*1.2
			is_sliding = false
			slide_jump_boost = true
		elif !is_sliding and !slide_jump_boost:
			velocity.y = jump_force
			can_jump = false


	# FOV
	velocity_clamped = clamp(velocity.length(), 0.5, SPRINTING_SPEED * 2)
	target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = (
	lerp(camera.fov, target_fov, delta * camera_delta_multiplier) 
	if (velocity_clamped >= 7) else lerp(camera.fov, BASE_FOV, delta * camera_delta_multiplier)
	)


	# Head tilt #HASDEBUG
	if head_leaning:
		tilt_axis = Input.get_action_strength("Left") - Input.get_action_strength("Right")
		camera_rotation = camera.rotation_degrees.z
		if is_on_floor():
			camera.rotation_degrees.z = clamp(lerp(camera.rotation_degrees.z 
			+ tilt_axis * tilt_amount,
			tilt_axis,delta * camera_delta_multiplier), -tilt_angle, tilt_angle)
			debug_flex3.text = str(camera.rotation_degrees.z) + " tilt" #not needed

		# Reset camera rotation if no movement keys are pressed #HASDEBUG
		if tilt_axis == 0:
			debug_flex3.text = str(camera.rotation_degrees.z) + " stopped moving" #not needed
			camera.rotation_degrees.z = (
			lerp(camera_rotation,0.0,delta * (camera_delta_multiplier * 3))# Reset rotation to zero
			)  


	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	
	if velocity != Vector3.ZERO and headbobbing:
		camera.transform.origin = (
			lerp(camera.transform.origin,headbob(t_bob),
			delta * camera_delta_multiplier)
			)
	elif velocity == Vector3.ZERO and headbobbing:
		camera.transform.origin = (
			lerp(camera.transform.origin,original_camera_pos,
			delta * camera_delta_multiplier)
			)


	# HUD Info #HASDEBUG
	debug_speed.text = "speed: " + str(current_speed)
	debug_velocity.text = "velocity: " + str(velocity)
	debug_FOV.text = "FOV: " + str(camera.fov)
	#not needed

	move_and_slide()


func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FQ) * BOB_AMP
	pos.x = sin(time * BOB_FQ/2) * BOB_AMP
	return pos


func coyoteTime(): #HASDEBUG
	await get_tree().create_timer(.15).timeout
	debug_flex1.text = "COYOTE expired" #not needed
	coyote_jump = false

# Settings Menu signals
func ChangeGravity(value):
	gravity = value


func ChangeJump(value):
	jump_force = value


func ChangeSpeed(value):
	WALKING_SPEED = value


func ChangeSprintSpeed(value):
	SPRINTING_SPEED = value
