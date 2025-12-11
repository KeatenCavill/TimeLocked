extends CharacterBody2D

@export var speed: float        = 50.0
@export var gravity: float      = 900.0
@export var max_health: int     = 4          # 3 HP
@export var knockback_force: float = 50.0    # smaller so they don't fly off
@export var knockback_up: float    = 40.0

# random pause settings
@export var pause_chance_per_sec: float = 0.25
@export var pause_time_min: float = 0.4
@export var pause_time_max: float = 1.2

var health: int
var direction: int = 1              # 1 = right, -1 = left

var is_attacking: bool = false
var is_hurt: bool      = false
var is_dead: bool      = false

var is_paused: bool    = false
var pause_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $Sprite
@onready var wall_ray: RayCast2D    = $WallRayCast
@onready var floor_ray: RayCast2D   = $FloorRayCast
@onready var hitbox: Area2D         = $Hitbox

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	rng.randomize()

	if anim:
		# Make sure hit / death / attack do NOT loop
		if anim.sprite_frames:
			if anim.sprite_frames.has_animation("Hit"):
				anim.sprite_frames.set_animation_loop("Hit", false)
			if anim.sprite_frames.has_animation("death"):
				anim.sprite_frames.set_animation_loop("death", false)
			if anim.sprite_frames.has_animation("Attack"):
				anim.sprite_frames.set_animation_loop("Attack", false)

		anim.animation = "Idle"
		anim.play()
		anim.animation_finished.connect(_on_animation_finished)

	if hitbox:
		hitbox.body_entered.connect(_on_Hitbox_body_entered)

	# Rays and sprite face right initially
	_apply_direction()


func _physics_process(delta: float) -> void:
	if is_dead:
		# DEAD: no gravity, no movement, just play death anim in place
		velocity = Vector2.ZERO
		_update_animation()
		return

	# normal gravity
	velocity.y += gravity * delta

	# handle random pauses
	_update_pause_state(delta)

	if not is_paused and not is_attacking and not is_hurt:
		# flip direction if edge or wall
		if not floor_ray.is_colliding() or wall_ray.is_colliding():
			_flip_direction()

		velocity.x = direction * speed
	else:
		# slow down horizontally while paused / attacking / hurt
		velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)

	move_and_slide()
	_update_animation()


# ---------------- DIRECTION & PATROL ----------------

func _apply_direction() -> void:
	# Flip sprite
	if anim:
		anim.flip_h = direction > 0

	# Wall ray points forward
	var wall_target: Vector2 = wall_ray.target_position
	wall_target.x = abs(wall_target.x) * direction
	wall_ray.target_position = wall_target

	# Floor ray is ahead in the walking direction
	var floor_pos: Vector2 = floor_ray.position
	floor_pos.x = abs(floor_pos.x) * direction
	floor_ray.position = floor_pos


func _flip_direction() -> void:
	direction *= -1
	_apply_direction()


func _update_pause_state(delta: float) -> void:
	if is_attacking or is_hurt:
		is_paused = false
		pause_timer = 0.0
		return

	if is_paused:
		pause_timer -= delta
		if pause_timer <= 0.0:
			is_paused = false
		return

	# chance per second to pause while walking on floor
	if is_on_floor() and abs(velocity.x) > 1.0:
		var chance_this_frame: float = pause_chance_per_sec * delta
		if rng.randf() < chance_this_frame:
			is_paused = true
			pause_timer = rng.randf_range(pause_time_min, pause_time_max)


# ---------------- ANIMATIONS ----------------

func _update_animation() -> void:
	if not anim:
		return

	if is_dead:
		if anim.animation != "death":
			anim.play("death")
	elif is_hurt:
		if anim.animation != "Hit":
			anim.play("Hit")
	elif is_attacking:
		if anim.animation != "Attack":
			anim.play("Attack")
	elif is_paused or abs(velocity.x) <= 1.0:
		if anim.animation != "Idle":
			anim.play("Idle")
	else:
		if anim.animation != "Run":
			anim.play("Run")


func _on_animation_finished() -> void:
	if not anim:
		return

	match anim.animation:
		"Hit":
			# Hit anim done → go back to normal AI
			is_hurt = false
		"Attack":
			is_attacking = false
		"death":
			# Death anim done → hide & stop processing
			hide()
			set_physics_process(false)
			set_process(false)
			# Optionally clear collisions too
			if hitbox:
				hitbox.monitoring = false
			# If you want them completely gone instead:
			# queue_free()


# ---------------- COMBAT ----------------

# Called from the player when their attack hits this enemy
func take_hit(dir: int) -> void:
	if is_dead:
		return

	is_hurt = true
	is_attacking = false
	is_paused = false
	pause_timer = 0.0

	health -= 1

	# gentle knockback away from player
	velocity.x = knockback_force * dir
	velocity.y = -knockback_up

	if health <= 0:
		_die()


# Hitbox touching the player
func _on_Hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if not body.is_in_group("Character"):
		return

	if body.has_method("receive_hit_from_enemy"):
		var dir_to_player: int = sign(body.global_position.x - global_position.x)
		if dir_to_player == 0:
			dir_to_player = 1
		body.receive_hit_from_enemy(dir_to_player)

	is_attacking = true


func _die() -> void:
	is_dead = true
	is_hurt = false
	is_attacking = false
	is_paused = false
	pause_timer = 0.0

	velocity = Vector2.ZERO

	# Turn off collisions so they can't hurt or be hit anymore
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if hitbox:
		hitbox.monitoring = false
