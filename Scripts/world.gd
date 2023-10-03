extends Node3D


@onready var menu = $Menu


func _ready():
	menu.visible = true
	menu.connect("start",GameStart)


func _physics_process(delta):
	if menu.visible:
		get_tree().paused = true
	else:
		get_tree().paused = false


func GameStart():
	menu.visible = false
