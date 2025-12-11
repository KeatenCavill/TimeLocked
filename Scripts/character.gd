extends CharacterBody2D

var SPEED = 200.0
const JUMP_VEL = -450.0
var jump_count = 0
var jump_max = 2
var is_falling = false

var wall_push = 200
var wall_jump_force = 250

var wall_slide_grav = 8.5
var wall_slideing = false

@onready var camera = get_node("Camera2D")
@onready var animationPlayer = get_node("AnimatedSprite2D")
@onready var Wall = get_node("RayCast")

@onready var circle_progress = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Attack hitbox (Area2D + its shape)
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
var attack_shape_base_x: float = 0.0

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
var Hold = 0.45

var coins_collected: int = 0

var Main: Node = null

# ---------------- ATTACK COMBO STATE ----------------
var is_attacking: bool = false

# Ground combo: 3 attacks
var ground_attack_index: int = 0
var last_ground_attack_time: float = 0.0

# Air combo: 3 attacks
var air_attack_index: int = 0
var last_air_attack_time: float = 0.0

var combo_reset_time: float = 0.5       # seconds

const ATTACK_ANIMS := ["attack1", "attack2", "attack3"]
const ATTACK_AIR_ANIMS := ["attack_air1", "attack_air2", "attack_air3"]

# Knockback from enemies
var is_knockedback: bool = false
var knockback_decay: float = 6000.0    # how fast horizontal knockback fades


func add_coin(amount: int):
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
	play_level_music(current_level)

	if attack_area and attack_shape:
		attack_area.monitoring = true
		attack_area.collision_mask = 0x7fffffff
		attack_shape_base_x = attack_shape.position.x

	if animationPlayer:
		animationPlayer.animation_finished.connect(_on_animation_finished)


# ---------------- PHYSICS ----------------

func _physics_process(delta: float) -> void:
	# Always lock camera to player, no drift
	if camera:
		camera.position = Vector2.ZERO

	velocity += get_gravity() * delta

	# knockback horizontal decay
	if is_knockedback:
		velocity.x = move_toward(velocity.x, 0, knockback_decay * delta)
		if abs(velocity.x) < 10.0:
			is_knockedback = false

	# only read movement input if we are not in knockback
	var direction := 0.0
	if not is_knockedback:
		direction = Input.get_axis("Move Left", "Move Right")

	if Input.is_action_pressed("Quit"):
		get_tree().quit()

	# ---- ATTACK INPUT (E mapped to "Attack") ----
	if Input.is_action_just_pressed("Attack"):
		start_attack()

	# Falling check
	if velocity.y > 0 and not is_on_floor():
		is_falling = true
	else:
		is_falling = false

	# Horizontal movement + run/idle anims
	if direction != 0.0:
		if is_on_floor():
			if not is_attacking:
				animationPlayer.play("run")
			if sfx_walk and not sfx_walk.playing:
				sfx_walk.play()
		else:
			if sfx_walk and sfx_walk.playing:
				sfx_walk.stop()

		velocity.x = direction * SPEED

		if velocity.x < 0:
			animationPlayer.flip_h = true
			Wall.scale.x = -1
			if attack_shape:
				attack_shape.position.x = -abs(attack_shape_base_x)
		if velocity.x > 0:
			animationPlayer.flip_h = false
			Wall.scale.x = 1
			if attack_shape:
				attack_shape.position.x = abs(attack_shape_base_x)
	else:
		if is_on_floor() and not is_knockedback:
			if not is_attacking:
				animationPlayer.play("Idle")
		if not is_knockedback:
			velocity.x = move_toward(velocity.x, 0, 2.0)
			velocity.x = 0

		if sfx_walk and sfx_walk.playing:
			sfx_walk.stop()

	# reset double jump
	if is_on_floor() or Wall_collider():
		jump_count = 0

	# falling anim
	if is_falling:
		if not is_attacking:
			animationPlayer.play("fall")

	# jump
	if Input.is_action_just_pressed("Jump") and jump_count < jump_max:
		if not is_attacking:
			animationPlayer.play("jump")

		if sfx_jump:
			sfx_jump.play()

		velocity.y = JUMP_VEL
		jump_count += 1
		if jump_count == jump_max:
			if not is_attacking:
				animationPlayer.play("doublejump")
			is_falling = false

	# wall sliding
	if Wall_collider() and !is_on_floor():
		if Input.is_action_pressed("Move Right") or Input.is_action_pressed("Move Left"):
			wall_slideing = true
		else:
			wall_slideing = false

		if wall_slideing:
			jump_max = 2
			velocity.y += wall_slide_grav * delta
			velocity.y = min(velocity.y, wall_slide_grav)
			if not is_attacking:
				animationPlayer.play("wallJump")

	if TimeLocked != true:
		# ---- FUTURE (E) ----
		if Input.is_action_pressed("Future"):
			hold_time_e += delta
			set_circle_progress(hold_time_e / Hold, Color(0.2, 0.4, 1.0))

			if sfx_tick and not sfx_tick.playing:
				sfx_tick.play()

			if hold_time_e >= Hold:
				if sfx_tick and sfx_tick.playing:
					sfx_tick.stop()
				load_level(1)
				hold_time_e = 0
				reset_circle_progress()
		elif Input.is_action_just_released("Future"):
			hold_time_e = 0
			reset_circle_progress()
			if sfx_tick and sfx_tick.playing:
				sfx_tick.stop()

		# ---- PRESENT (W) ----
		if Input.is_action_pressed("Present"):
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
		if Input.is_action_pressed("Past"):
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
	circle_progress.material.set_shader_parameter("progress", 0.0)


var loading_index = -1
var pending_pos: Vector2 = Vector2.ZERO


#load level function, deletes scene from main then adds new scene
func load_level(index):
	if index == current_level:
		return

	if index >= 0 and index < Level_positions.size():
		var offset_diff = Level_positions[index] - Level_positions[current_level]

		var target_pos: Vector2 = global_position
		target_pos.y += offset_diff

		var safe_pos: Vector2 = find_safe_teleport_position(target_pos)
		global_position = safe_pos

		if sfx_woosh:
			sfx_woosh.play()

		if sfx_walk and sfx_walk.playing:
			sfx_walk.stop()

		current_level = index
		update_coin_animation(index)

		play_level_music(current_level)
		

	is_falling = false

	var target_main: Node = Main if Main != null else get_tree().current_scene
	if target_main and target_main.has_method("flash_white"):
		target_main.flash_white()


func update_coin_animation(index):
	var root = Main if Main else get_parent()
	var level_holder = root.get_node("LevelHolder")

	for level in level_holder.get_children():
		for coin in level.find_children("", "Area2D", true, false):
			if coin and coin.has_method("play_for_level"):
				coin.play_for_level(index)


# --- MUSIC CONTROL ---

func play_level_music(level_index: int) -> void:
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
	if is_position_safe(base_pos):
		return base_pos

	var max_radius := 1000.0
	var step := 8.0

	for radius in range(int(step), int(max_radius) + 1, int(step)):
		for angle_deg in [0, 90, 180, 270, 45, 135, 225, 315]:
			var angle_rad = deg_to_rad(angle_deg)
			var offset = Vector2(cos(angle_rad), sin(angle_rad)) * radius
			var candidate = base_pos + offset

			if is_position_safe(candidate):
				return candidate

	return base_pos


# ---------------- ATTACK HELPERS ----------------

func start_attack() -> void:
	if is_attacking:
		return

	var is_air_attack: bool = (not is_on_floor()) or (abs(velocity.x) > 0.1)
	var now := float(Time.get_ticks_msec()) / 1000.0

	if is_air_attack:
		if now - last_air_attack_time > combo_reset_time:
			air_attack_index = 0
		else:
			air_attack_index += 1
			if air_attack_index >= ATTACK_AIR_ANIMS.size():
				air_attack_index = 0

		is_attacking = true
		var anim_name_air: String = ATTACK_AIR_ANIMS[air_attack_index]
		if animationPlayer:
			animationPlayer.play(anim_name_air)
	else:
		if now - last_ground_attack_time > combo_reset_time:
			ground_attack_index = 0
		else:
			ground_attack_index += 1
			if ground_attack_index >= ATTACK_ANIMS.size():
				ground_attack_index = 0

		is_attacking = true
		var anim_name_ground: String = ATTACK_ANIMS[ground_attack_index]
		if animationPlayer:
			animationPlayer.play(anim_name_ground)

	# Immediately check for anything in front of us and apply damage
	_perform_attack_hit_check()


func _on_animation_finished() -> void:
	var current_name: String = animationPlayer.animation

	if current_name in ATTACK_ANIMS:
		is_attacking = false
		last_ground_attack_time = float(Time.get_ticks_msec()) / 1000.0
	elif current_name in ATTACK_AIR_ANIMS:
		is_attacking = false
		last_air_attack_time = float(Time.get_ticks_msec()) / 1000.0


func _perform_attack_hit_check() -> void:
	if attack_shape == null or attack_shape.shape == null:
		return

	var dir := -1 if animationPlayer.flip_h else 1

	var space_state = get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = attack_shape.shape
	params.transform = attack_shape.global_transform
	params.collision_mask = 0x7fffffff
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var results = space_state.intersect_shape(params, 32)

	for r in results:
		var collider: Node = r.collider
		if collider == null:
			continue

		if collider.is_in_group("enemies") and collider.has_method("take_hit"):
			collider.take_hit(dir)
		else:
			var parent := collider.get_parent()
			if parent and parent.is_in_group("enemies") and parent.has_method("take_hit"):
				parent.take_hit(dir)


# Called by enemies when they hit the player
func receive_hit_from_enemy(dir: int) -> void:
	is_knockedback = true
	var knockback_force := 2000.0   # BIG shove
	velocity.x = knockback_force * dir
	velocity.y = -300.0
	_flash_white()


func _flash_white() -> void:
	var sprite: CanvasItem = animationPlayer
	var original: Color = sprite.modulate
	var tween := create_tween()
	for i in range(3):
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.4), 0.05)
	tween.tween_property(sprite, "modulate", original, 0.05)
