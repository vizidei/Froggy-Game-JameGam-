extends Area2D

@export var flower_scene : PackedScene

const SPAWN_MIN : float = 8.0     # seconds between spawn attempts
const SPAWN_MAX : float = 30.0
const SPAWN_AREA : float = 0.2    # share of the pad's radius the flower can appear in

@onready var shape: CollisionShape2D = $CollisionShape2D

var flower : Node2D

func _ready() -> void:
	spawn_loop()

func spawn_loop() -> void:
	while true:
		await get_tree().create_timer(randf_range(SPAWN_MIN, SPAWN_MAX)).timeout
		if not is_instance_valid(flower):
			spawn_flower()

func spawn_flower() -> void:
	if flower_scene == null:
		return
	var radius : float = 20.0
	if shape.shape is CircleShape2D:
		radius = shape.shape.radius
	flower = flower_scene.instantiate()
	flower.position = Vector2.from_angle(randf() * TAU) * radius * SPAWN_AREA * sqrt(randf())
	add_child(flower)
