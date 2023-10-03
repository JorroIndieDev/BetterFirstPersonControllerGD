extends Node3D




func _ready():
	$Player/Head/Camera3D/debug_screen/FLEX2.text = "SwitchCam: " + str(!$Player/Head/Camera3D.current)


func _unhandled_input(_event):
	if Input.is_action_just_pressed("SwitchCam"):
		$Player/Head/Camera3D/debug_screen/FLEX2.text = "SwitchCam: " + str($Player/Head/Camera3D.current)
		$Player/Head/Camera3D.current = !$Player/Head/Camera3D.current


func _physics_process(_delta):
	pass


