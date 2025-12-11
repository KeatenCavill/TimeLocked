extends Node2D

@onready var flash: ColorRect        = $UI/Flash
@onready var black: ColorRect        = $UI/BlackFade
@onready var player: CharacterBody2D = $Character
@onready var level_holder: Node      = $LevelHolder

# Popup and map images
@onready var map_popup: Control      = $UI/MapPopup
@onready var map_image_root: Node    = $UI/MapPopup/ColorRect/MapImage
@onready var present_map: TextureRect = $UI/MapPopup/ColorRect/MapImage/PresentMap
@onready var future_map:  TextureRect = $UI/MapPopup/ColorRect/MapImage/FutureMap
@onready var past_map:    TextureRect = $UI/MapPopup/ColorRect/MapImage/PastMap

@export var enemy_scene: PackedScene

var fade_duration: float = 1.5

# Enemy spawn points (same as before; tweak as needed)
var enemy_spawn_points: Array[Vector2] = [
	Vector2(200, 0),
	Vector2(800, 0),
	Vector2(-400, 0)
]

# Map open/close SFX players
var map_open_sfx: AudioStreamPlayer
var map_close_sfx: AudioStreamPlayer


func _ready() -> void:
	flash.modulate.a = 0.0
	black.modulate.a = 0.0

	# Let the character know about Main (coins label, flash, etc.)
	player.set_main(self)

	# Start with popup hidden
	if map_popup:
		map_popup.visible = false

	# Set initial map visibility (present by default)
	_update_map_texture()

	# Create audio players for open/close sounds
	_setup_map_sounds()

	_spawn_enemies()


func _process(_delta: float) -> void:
	# Tab (or whatever) should be mapped to this action in InputMap
	if Input.is_action_just_pressed("toggle_minimap"):
		if map_popup:
			if not map_popup.visible:
				# We are opening the map
				_update_map_texture()
				map_popup.visible = true
				if map_open_sfx:
					map_open_sfx.play()
			else:
				# We are closing the map
				map_popup.visible = false
				if map_close_sfx:
					map_close_sfx.play()

	# If the map is open, keep the image synced with the player's current time
	if map_popup and map_popup.visible:
		_update_map_texture()


# ---------------- SETUP MAP SOUNDS ----------------

func _setup_map_sounds() -> void:
	# Open sound
	map_open_sfx = AudioStreamPlayer.new()
	map_open_sfx.stream = preload("res://Assets/Sounds/Pageturn-open.mp3")
	add_child(map_open_sfx)

	# Close sound
	map_close_sfx = AudioStreamPlayer.new()
	map_close_sfx.stream = preload("res://Assets/Sounds/Pageturn-close.mp3")
	add_child(map_close_sfx)


# ---------------- MAP IMAGE SELECTION ----------------

func _update_map_texture() -> void:
	if player == null:
		return

	# Hide all maps first
	present_map.visible = false
	future_map.visible  = false
	past_map.visible    = false

	# Use player's current_level to decide which map to show
	var lvl: int = 0
	if "current_level" in player:
		lvl = player.current_level

	match lvl:
		0:
			present_map.visible = true   # Present
		1:
			future_map.visible = true    # Future
		2:
			past_map.visible = true      # Past
		_:
			present_map.visible = true   # fallback


# ---------------- FLASH WHITE (used by character on time jump) ----------------

func flash_white() -> void:
	flash.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 1.0, 0.1)
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)


# ---------------- ENEMY SPAWN ----------------

func _spawn_enemies() -> void:
	if enemy_scene == null:
		return

	for pos in enemy_spawn_points:
		var enemy := enemy_scene.instantiate()
		if enemy is Node2D:
			(enemy as Node2D).global_position = pos
		level_holder.add_child(enemy)


# ---------------- FADE TO CREDITS ----------------

func fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(black, "modulate:a", 1.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "load_credits"))

func load_credits() -> void:
	var credits_scene: PackedScene = load("res://Scenes/GodotCredits.tscn")
	get_tree().change_scene_to_packed(credits_scene)
