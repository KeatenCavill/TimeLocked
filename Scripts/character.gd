extends CharacterBody2D

var SPEED = 200.0
const JUMP_VEL = -450.0
var jump_count = 0
var jump_max = 2
var is_falling = false


var wall_push= 200
var wall_jump_force = 250

var wall_slide_grav = 8.5
var wall_slideing = false

@onready var camera = get_node("Camera2D")
@onready var animationPlayer = get_node("AnimatedSprite2D")
@onready var Wall = get_node("RayCast")

@onready var circle_progress = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# --- AUDIO: SFX ---
@onready var sfx_walk: AudioStreamPlayer2D = $walkingSFX
@onready var sfx_jump: AudioStreamPlayer2D = $jumpSFX
@onready var sfx_tick: AudioStreamPlayer2D = $tickSFX
@onready var sfx_woosh: AudioStreamPlayer2D = $woshSFX

# --- AUDIO: MUSIC PER LEVEL ---
@onready var music_level0: AudioStreamPlayer = $MusicLevel0
@onready var music_level1: AudioStreamPlayer = $MusicLevel1
@onready var music_level2: AudioStreamPlayer = $MusicLevel2



var TimeLocked = false


@export var Level_positions: Array[float] = [
	0.0,
	-10000.0, 
	10000.0
	]

var current_level = 0
var hold_time_e = 0.0
var hold_time_q = 0.0
var hold_time_w = 0.0
var Hold = 0.75

var coins_collected: int = 0

var Main:Node = null

func add_coin(amount:int):
	coins_collected += amount
	Globals.Coins_collected = coins_collected
	
	
	if Main and Main.has_node("UI/Coins"):
		var label = Main.get_node("UI/Coins")
		label.text = "Coins: %d" % coins_collected

func set_main(value):
	Main = value

func _ready():
	current_level = 0
	add_to_group("Character")
	# start music for initial level
	play_level_music(current_level)

# physics
func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	camera.offset.x = move_toward(camera.offset.x, 0, 0.5)
	
	#checks for movement
	var direction := Input.get_axis("Move Left", "Move Right");
	
	if Input.is_action_pressed("Quit"):
		get_tree().quit()

	#Checks for falling
	if velocity.y > 0 and not is_on_floor():
		is_falling = true
	else:
		is_falling = false

	# moves player and plays appropriate animation
	if direction:
		if(is_on_floor()):
			animationPlayer.play("run")
			# --- walking sound only when moving on ground ---
			if sfx_walk and not sfx_walk.playing:
				sfx_walk.play()
		else:
			# airborne or wall sliding, stop walk sound
			if sfx_walk and sfx_walk.playing:
				sfx_walk.stop()
		
		velocity.x = direction * SPEED
		print(velocity.x)
		if velocity.x < 0:
			animationPlayer.flip_h = true
			Wall.scale.x = -1
		if velocity.x > 0:
			animationPlayer.flip_h = false
			Wall.scale.x = 1
	else:
		if(is_on_floor()):
			animationPlayer.play("Idle")
		velocity.x = move_toward(velocity.x, 0, 2.0)
		velocity.x = 0
		
		# stop walking sound when not moving
		if sfx_walk and sfx_walk.playing:
			sfx_walk.stop()
		
	#resets double jump
	if is_on_floor() or Wall_collider():
		jump_count = 0
		
	#sets falling animation
	if is_falling:
		animationPlayer.play("fall")
	
	
	#jump
	if Input.is_action_just_pressed("Jump") and jump_count < jump_max:
		animationPlayer.play("jump")
		
		# --- jump sound ---
		if sfx_jump:
			sfx_jump.play()
		
		velocity.y = JUMP_VEL
		jump_count += 1
		print("jump + 1")
		print(jump_count)
		if jump_count == jump_max:
			animationPlayer.play("doublejump")
			is_falling = false
			
		camera.offset.x = camera.offset.x + 10
			
	#wall sliding
	if Wall_collider() and !is_on_floor():
		
		if Input.is_action_pressed("Move Right") or Input.is_action_pressed("Move Left"):
			wall_slideing =  true
		else:
			wall_slideing = false
		
		if wall_slideing:
			jump_max = 2
			velocity.y += wall_slide_grav * delta
			velocity.y = min(velocity.y, wall_slide_grav)
			animationPlayer.play("wallJump")


	if TimeLocked != true:
		# ---- FUTURE (E) ----
		if Input.is_action_pressed("Future"): #3, 
			hold_time_e += delta
			set_circle_progress(hold_time_e / Hold, Color(0.2,0.4,1.0))
			
			# ticking only while key is held
			if sfx_tick and not sfx_tick.playing:
				sfx_tick.play()
		
			if hold_time_e >= Hold:
				# finished charge: stop ticking and time jump
				if sfx_tick and sfx_tick.playing:
					sfx_tick.stop()
				load_level(1)
				hold_time_e = 0
				reset_circle_progress()
		elif Input.is_action_just_released("Future"):
			hold_time_e = 0
			reset_circle_progress()
			# stop ticking when key released
			if sfx_tick and sfx_tick.playing:
				sfx_tick.stop()

		# ---- PRESENT (W) ----
		if Input.is_action_pressed("Present"): # 2, 
			hold_time_w += delta
			set_circle_progress(hold_time_w / Hold, Color(0.2, 1.0, 0.2))
			
			if sfx_tick and not sfx_tick.playing:
				sfx_tick.play()
			
			if hold_time_w >= Hold:
				if sfx_tick and sfx_tick.playing:
					sfx_tick.stop()
				load_level(0)
				hold_time_w = 0
				reset_circle_progress()
		elif Input.is_action_just_released("Present"):
			hold_time_w = 0
			reset_circle_progress()
			if sfx_tick and sfx_tick.playing:
				sfx_tick.stop()
		
		# ---- PAST (Q) ----
		if Input.is_action_pressed("Past"): # 1, 
			hold_time_q += delta
			set_circle_progress(hold_time_q / Hold, Color(1.0, 0.2, 0.2))
			
			if sfx_tick and not sfx_tick.playing:
				sfx_tick.play()
		
			if hold_time_q >= Hold:
				if sfx_tick and sfx_tick.playing:
					sfx_tick.stop()
				load_level(2)
				hold_time_q = 0
				reset_circle_progress()
		elif Input.is_action_just_released("Past"):
			hold_time_q = 0
			reset_circle_progress()
			if sfx_tick and sfx_tick.playing:
				sfx_tick.stop()
			



	move_and_slide()

	
func Wall_collider():
	return Wall.is_colliding()
	
#process Circle Color
func set_circle_progress(value: float, color: Color):
	circle_progress.visible = true
	circle_progress.material.set_shader_parameter("progress", value)
	circle_progress.material.set_shader_parameter("bar_color", color)
	
#Reset Progress Circle
func reset_circle_progress():
	circle_progress.visible = false
	circle_progress.material.set_shader_parameter("progress",0.0)
	
	
	
var loading_index = -1
var pending_pos : Vector2 = Vector2.ZERO
	
#load level function, deletes scene from main then adds new scene
func load_level(index):
	if index == current_level:
		return
	
	if index >= 0 and index < Level_positions.size():
		var offset_diff = Level_positions[index] - Level_positions[current_level]
		
		# Compute the raw target position for this time layer
		var target_pos: Vector2 = global_position
		target_pos.y += offset_diff
		
		# Use the safe-teleport helper so we don't end up inside a wall
		var safe_pos: Vector2 = find_safe_teleport_position(target_pos)
		global_position = safe_pos
		
		# --- time jump woosh sound ---
		if sfx_woosh:
			sfx_woosh.play()
		
		# optional: stop walking sound during jump
		if sfx_walk and sfx_walk.playing:
			sfx_walk.stop()
		
		current_level = index
		update_coin_animation(index)
		
		# --- switch level music ---
		play_level_music(current_level)
	
	is_falling = false

	var main = get_tree().root.get_node("Main")
	if main.has_method("flash_white"):
		main.flash_white()
		

func update_coin_animation(index):
	var root = Main if Main else get_parent()
	var level_holder = root.get_node("LevelHolder")
	
	for level in level_holder.get_children():
		for coin in level.find_children("", "Area2D", true, false):
			if coin and coin.has_method("play_for_level"):
				coin.play_for_level(index)


# --- MUSIC CONTROL ---

func play_level_music(level_index: int) -> void:
	# stop all first
	if music_level0 and music_level0.playing:
		music_level0.stop()
	if music_level1 and music_level1.playing:
		music_level1.stop()
	if music_level2 and music_level2.playing:
		music_level2.stop()
	
	match level_index:
		0:
			if music_level1:
				music_level1.play()
		1:
			if music_level0:
				music_level0.play()
		2:
			if music_level2:
				music_level2.play()


# ---------- SAFE TELEPORT HELPERS ----------

func is_position_safe(test_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	var shape_params := PhysicsShapeQueryParameters2D.new()
	shape_params.shape = collision_shape.shape
	shape_params.transform = Transform2D(0.0, test_pos)
	shape_params.collision_mask = collision_mask
	shape_params.collide_with_areas = false
	shape_params.collide_with_bodies = true
	
	var result = space_state.intersect_shape(shape_params, 1)
	return result.is_empty()


func find_safe_teleport_position(base_pos: Vector2) -> Vector2:
	# Try the exact base position first
	if is_position_safe(base_pos):
		return base_pos
	
	var max_radius := 1000.0  # how far to search (pixels)
	var step := 8.0         # search granularity
	
	for radius in range(int(step), int(max_radius) + 1, int(step)):
		for angle_deg in [0, 90, 180, 270, 45, 135, 225, 315]:
			var angle_rad = deg_to_rad(angle_deg)
			var offset = Vector2(cos(angle_rad), sin(angle_rad)) * radius
			var candidate = base_pos + offset
			
			if is_position_safe(candidate):
				return candidate
	
	# If nothing was found in the search radius, just return the base position
	# (you could also cancel the jump or handle this differently if you want)
	return base_pos
