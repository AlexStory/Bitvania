extends KinematicBody2D

const DustEffect = preload("res://Effects/DustEffect.tscn")

export (int) var ACCELERATION: int = 512
export (int) var MAX_SPEED: int = 64
export (float) var FRICTION: float = 0.25
export (int) var GRAVITY: = 200
export (int) var JUMP_FORCE = 128
export (int) var MAX_SLOPE_ANGLE = 46

onready var sprite_animator: AnimationPlayer = $SpriteAnimator
onready var sprite: Sprite = $Sprite
onready var coyote_jump_timer := $CoyoteJumpTimer

var motion: Vector2 = Vector2.ZERO
var snap_vector = Vector2.ZERO
var just_jumped := false

func _physics_process(delta: float):
	just_jumped = false
	var input_vector: Vector2 = get_input_vector()
	apply_horizontal_force(delta, input_vector)
	apply_friction(input_vector)
	update_snap_vector()
	jump_check()
	apply_gravity(delta)
	update_animations(input_vector)
	move()


func create_dust_effect():
	var dust_position = global_position
	dust_position.x += rand_range(-4, 4)
	var dust_effect = DustEffect.instance()
	get_tree().current_scene.add_child(dust_effect)
	dust_effect.global_position = dust_position


func get_input_vector() -> Vector2:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	return input_vector


func apply_horizontal_force(delta: float, input_vector: Vector2):
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_friction(input_vector: Vector2):
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0.0, FRICTION)


func update_snap_vector():
	if is_on_floor():
		snap_vector = Vector2.DOWN


func jump_check():
	if is_on_floor() or coyote_jump_timer.time_left > 0:
		if Input.is_action_just_pressed("ui_up"):
			motion.y = -JUMP_FORCE
			snap_vector = Vector2.ZERO
			just_jumped = true
	else:
		if Input.is_action_just_released("ui_up") and motion.y < -JUMP_FORCE/2:
			motion.y = -JUMP_FORCE / 2
	
func apply_gravity(delta: float):
	if !is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)
	

func update_animations(input_vector: Vector2):
	sprite.scale.x = sign(get_local_mouse_position().x)
	if input_vector.x != 0:
		sprite_animator.play("Run")
		sprite_animator.playback_speed = input_vector.x * sprite.scale.x
	else:
		sprite_animator.playback_speed = 1
		sprite_animator.play("Idle")
		
	if !is_on_floor():
		sprite_animator.play("Jump")

func move():
	var was_in_air := not is_on_floor()
	var was_on_floor := is_on_floor()
	var last_position := position
	var last_motion := motion
	
	motion = move_and_slide_with_snap(motion, snap_vector * 4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))
	
	# just left ground
	if was_on_floor and not is_on_floor() and not just_jumped:
		motion.y = 0
		position.y = last_position.y
		coyote_jump_timer.start()

	# landing
	if was_in_air and is_on_floor():
		motion.x = last_motion.x
		create_dust_effect()
		
	# prevent sliding
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		position.x = last_position.x
		
