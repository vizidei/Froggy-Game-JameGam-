extends "res://scripts/enemy.gd"

enum State { CHASE, WINDUP, DASH, RECOVER }

const CHARGE_RANGE : float = 350.0   # distance that triggers a charge
const WINDUP_TIME : float = 0.6      # the warning flash
const DASH_SPEED : float = 220.0     # your frog's dash is 300, so this is dodgeable
const DASH_TIME : float = 0.8
const RECOVER_TIME : float = 0.5   # it stands still: your window to hit it

var state : State = State.CHASE
var state_timer : float = 0.0
var charge_dir : Vector2 = Vector2.ZERO
var charge_cooldown : float = 2.0

func _ready() -> void:
	super()
	health = 40.0
	charge_cooldown = randf_range(1.0, 2.5)

func _physics_process(delta: float) -> void:
	if dead or player == null:
		super(delta)
		return

	var dir : Vector2 = global_position.direction_to(player.global_position)

	match state:
		State.CHASE:
			super(delta)   # normal chasing and wobble
			charge_cooldown -= delta
			if charge_cooldown <= 0.0 and global_position.distance_to(player.global_position) < CHARGE_RANGE:
				state = State.WINDUP
				state_timer = WINDUP_TIME
				velocity = Vector2.ZERO

		State.WINDUP:
			state_timer -= delta
			face(dir, delta)
			sprite.modulate = Color(1.0, 0.3, 0.3) if int(state_timer * 12.0) % 2 == 0 else Color.WHITE
			if state_timer <= 0.0:
				charge_dir = dir
				state = State.DASH
				state_timer = DASH_TIME
				sprite.modulate = Color(1.0, 0.475, 0.839, 1.0)

		State.DASH:
			state_timer -= delta
			velocity = charge_dir * DASH_SPEED
			move_and_slide()
			face(charge_dir, delta)
			if state_timer <= 0.0:
				state = State.RECOVER
				state_timer = RECOVER_TIME
				velocity = Vector2.ZERO

		State.RECOVER:
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE
				charge_cooldown = randf_range(2.0, 3.5)

func face(dir: Vector2, delta: float) -> void:
	facing_rot = lerp_angle(facing_rot, dir.angle() + SPRITE_OFFSET, 1.0 - exp(-TURN_SPEED * delta))
	sprite.rotation = facing_rot
	sprite.flip_v = dir.x > 0.0
