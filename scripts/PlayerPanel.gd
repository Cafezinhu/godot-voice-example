extends MarginContainer
onready var muted_icon = $HBoxContainer/MutedIcon
onready var nickname_label = $HBoxContainer/Label

puppetsync var muted = false
puppetsync var nickname = ""

func _process(_delta):
	muted_icon.visible = muted
	nickname_label.text = nickname
