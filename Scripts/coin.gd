extends Area2D

@export var value:int = 1

@onready var animationPlayer = $AnimatedSprite2D
@onready var audio: AudioStreamPlayer2D = $pickupSFX

func _ready():
	animationPlayer.play("Silver")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Character"):
		body.add_coin(value)

		# hide coin visuals immediately
		visible = false
		set_collision_layer(0)
		set_collision_mask(0)

		# play sound
		audio.play()

		# free AFTER sound ends
		audio.connect("finished", Callable(self, "_on_audio_finished"), CONNECT_ONE_SHOT)

func _on_audio_finished():
	queue_free()


func play_for_level(index):
	match index:
		0:
			animationPlayer.play("Silver")
		1:
			animationPlayer.play("Bronze")
		2:
			animationPlayer.play("Gold")
		_:
			animationPlayer.play("Silver")
