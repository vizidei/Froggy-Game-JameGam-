extends CharacterBody2D

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

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

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
		sprite.rotation = lerp_angle(sprite.rotation, dir.angle() + SPRITE_OFFSET, 1.0 - exp(-TURN_SPEED * delta))
		sprite.flip_v = dir.x > 0.0   # keeps the bug right-side up when facing left


func take_damage(amount: float, dir: Vector2) -> void:
	if dead:
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
