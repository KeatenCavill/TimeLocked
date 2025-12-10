extends Node2D

@onready var flash = $UI/Flash
@onready var player = $Character
@onready var Levels = $LevelHolder

@onready var camera = $Character/Camera2D
@onready var level_holder = $LevelHolder

@onready var black = $UI/BlackFade
var fade_durration = 1.5

func _ready():
	flash.modulate.a = 0.0
	black.modulate.a = 0.0
	player.set_main(self)
	
func flash_white():
	var tween = create_tween()
	# Fade in to full white
	tween.tween_property(flash, "modulate:a", 1.0, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade back out to transparent
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func fade_to_black():

	# Fade in black screen
	var tween = create_tween()
	tween.tween_property(black, "modulate:a", 1.0, fade_durration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade back out to transparent
		
	tween.tween_callback(Callable(self, "load_credits"))
	
func load_credits():
	var credits_scene = load("res://Scenes/GodotCredits.tscn")
	get_tree().change_scene_to_packed((credits_scene))
	
