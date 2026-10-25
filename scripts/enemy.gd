extends CharacterBody2D

const WOBBLE_SPEED : float = 12.0
const WOBBLE_ANGLE : float = 0.12    # radians, about 7 degrees
const BUZZ_SPEED : float = 20.0
const BUZZ_AMOUNT : float = 0.08     # squish strength

var anim_time : float = 0.0
var phase : float = randf() * TAU    # random offset so bugs don't move in sync
var facing_rot : float = 0.0
var base_scale : Vector2

const SPEED : float = 100.0        
const LAUNCH_SPEED : float = 400.0
const LAUNCH_DRAG : float = 2.0
const FLY_TIME : float = 0.8

const SPRITE_OFFSET : float = PI  # see the note below
const TURN_SPEED : float = 12.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var health : float = 30.0
var dead : bool = false
var launch_velocity : Vector2 = Vector2.ZERO
var spin : float = 0.0
var player : Node2D

var immune_until : int = 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	base_scale = sprite.scale

func _physics_process(delta: float) -> void:
	if dead:
		# ragdoll: no collisions, just slide, slow down, and spin
		global_position += launch_velocity * delta
		launch_velocity = launch_velocity.lerp(Vector2.ZERO, 1.0 - exp(-LAUNCH_DRAG * delta))
		rotation += spin * delta
		return

	if player:
		var dir : Vector2 = global_position.direction_to(player.global_position)
		velocity = dir * SPEED
		move_and_slide()

		anim_time += delta
		facing_rot = lerp_angle(facing_rot, dir.angle() + SPRITE_OFFSET, 1.0 - exp(-TURN_SPEED * delta))
		sprite.rotation = facing_rot + sin(anim_time * WOBBLE_SPEED + phase) * WOBBLE_ANGLE
		sprite.flip_v = dir.x > 0.0

		var buzz : float = sin(anim_time * BUZZ_SPEED + phase)
		sprite.scale = base_scale * Vector2(1.0 + buzz * BUZZ_AMOUNT, 1.0 - buzz * BUZZ_AMOUNT)


func take_damage(amount: float, dir: Vector2) -> void:
	if dead:
		return
	if Time.get_ticks_msec() < immune_until:
		return
	health -= amount
	if health <= 0.0:
		die(dir)

func die(dir: Vector2) -> void:
	dead = true
	ScoreManager.register_kill(global_position)
	col_shape.set_deferred("disabled", true)   # stops hurting the frog and stops being hit
	launch_velocity = dir * LAUNCH_SPEED
	spin = randf_range(12.0, 20.0) * (1 if randf() > 0.5 else -1)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FLY_TIME)
	await tween.finished
	print("enemy defeated")
	queue_free()
