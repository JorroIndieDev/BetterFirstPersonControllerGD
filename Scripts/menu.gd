extends Control

signal start

func _ready():
	pass 


func _process(_delta):
	pass


func _on_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/test_level.tscn")
