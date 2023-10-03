extends Control

# Basic settings
@onready var gravity_value = $Gravity/LineEdit
@onready var jump_value = $JumpHight/LineEdit2


signal gravity_setting_change(value)
signal jump_setting_change(value)
signal speed_setting_change(value)
signal sprint_speed_setting_change(value)


func _ready():
	pass


func _process(_delta):
	pass


func _on_line_edit_text_submitted(new_text):
	emit_signal("gravity_setting_change",float(new_text))


func _on_line_edit_2_text_submitted(new_text):
	emit_signal("jump_setting_change",float(new_text))


func _on_line_edit_3_text_submitted(new_text):
	emit_signal("speed_setting_change",float(new_text))


func _on_line_edit_4_text_submitted(new_text):
	emit_signal("sprint_speed_setting_change",float(new_text))
