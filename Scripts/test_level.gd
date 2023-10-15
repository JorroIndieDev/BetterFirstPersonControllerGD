extends Node3D

@export var player:Node


func _ready():
	$Player/Neck/Head/Camera3D/debug_screen/FLEX2.text = "SwitchCam: " + str(!$Player/Neck/Head/Camera3D.current)
#	player.gravity = 10 if player.gravity == 0 else player.gravity == player.gravity
	print(player.gravity)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("SwitchCam"):
		$Player/Neck/Head/Camera3D/debug_screen/FLEX2.text = "SwitchCam: " + str($Player/Neck/Head/Camera3D.current)
		$Player/Neck/Head/Camera3D.current = !$Player/Head/Camera3D.current


func _physics_process(_delta):
	
	pass


