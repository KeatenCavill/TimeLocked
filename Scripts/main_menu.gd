extends Control

@onready var menu_music: AudioStreamPlayer = $MenuMusic

# Assign 2+ different songs here in the Inspector
@export var menu_tracks: Array[AudioStream] = []

func _ready():
	randomize()
	# Pick a random track for the menu
	if menu_tracks.size() > 0:
		var idx := randi() % menu_tracks.size()
		print("Menu picked track index:", idx) # debug

		menu_music.stream = menu_tracks[idx]

		# Make sure it loops
		if menu_music.stream:
			menu_music.stream.loop = true

		menu_music.play()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
