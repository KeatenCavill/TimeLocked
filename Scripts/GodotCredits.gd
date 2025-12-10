extends Node2D

const section_time := 2.0
const line_time := 0.3
const base_speed := 100
const speed_up_multiplier := 10.0
const title_color := Color.RED

var scroll_speeds := base_speed
var speed_up := false

@onready var line := $CreditsContainer/Line
var started := false
var finished := false

var section
var section_next := true
var section_timer := 0.0
var line_timer := 0.0
var curr_line := 0
var lines := []

var Coins_collected = 0 

@onready var menu_music: AudioStreamPlayer = $CreditMusic

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

var credits = [
	[
		"Time Locked - Demo",
		"",
		"A game by Keaten C"
	],[
		"Programming",
		"",
		"Keaten",
		"",
	],[
		"Assets:",
		"",
		"Animated Pixel Adventure by Rvros",
		"",
		"Free Pielart Platformer TIleset by aamatnikss",
		"",
		"HI_Bit Fantasy Jungle Platformer Tileset by aamatnikess",
		"",
		"High qualtiy Foggy Cliffs - Fantasy Tileset by aamatnikess",
		"",
		"Coin, Potion, Gem assets by Hypedigi",
	],[
		
	],[
		"Music and SFX:",
		"",
		"jump sound from 'Free Sound assest pack' by Ne Mene",
		"",
		"Cozie Toons by Pizza Doggy",
		"",
		"Songs included: 'Drifting Memories', 'Floating Dream', and 'Strange Worlds",
		"",
		"'Clock Ticking' by RedDog0607",
		"",
		"'Whoosh Cinematic Sound Effect' by DRAGON-STUDIO",
	],[
		
	],[
		"Tools used",
		"",
		"Developed with Godot Engine",
		"",
	],[
		
		"You Collected :",
		"",
		str(Globals.Coins_collected) + " Coins",
		"",
		"out of 101."
		

	]
]


func _process(delta):
	var scroll_speed = base_speed * delta
	
	if section_next:
		section_timer += delta * speed_up_multiplier if speed_up else delta
		if section_timer >= section_time:
			section_timer -= section_time
			
			if credits.size() > 0:
				started = true
				section = credits.pop_front()
				curr_line = 0
				add_line()
	
	else:
		line_timer += delta * speed_up_multiplier if speed_up else delta
		if line_timer >= line_time:
			line_timer -= line_time
			add_line()
	
	if speed_up:
		scroll_speed *= speed_up_multiplier
	
	if lines.size() > 0:
		for l in lines:
			l.position.y += scroll_speed
			if l.position.y < -l.get_line_height():
				lines.erase(l)
				l.queue_free()
	elif started:
		finish()


func finish():
	if not finished:
		finished = true
		self.queue_free()
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")




func add_line():
	if section == null or section.is_empty():
		return
	var new_line = line.duplicate()
	new_line.text = section.pop_front()
	lines.append(new_line)
	if curr_line == 0:
		new_line.set("theme_override_colors/font_color",title_color)
	$CreditsContainer.add_child(new_line)
	
	if section.size() > 0:
		curr_line += 1
		section_next = false
	else:
		section_next = true


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		finish()
	if event.is_action_pressed("ui_down") and !event.is_echo():
		speed_up = true
	if event.is_action_released("ui_down") and !event.is_echo():
		speed_up = false
