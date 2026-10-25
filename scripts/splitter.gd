extends "res://scripts/enemy.gd"

@export var spawn_scene : PackedScene   # drag bug.tscn in the Inspector

const SPLIT_COUNT : int = 2
const SPLIT_SCALE : float = 0.6

func _ready() -> void:
	super()
	health = 60.0   # two hits with your current weapon damage

func die(dir: Vector2) -> void:
	split()
	super(dir)

func split() -> void:
	if spawn_scene == null:
		return
	var parent := get_parent()
	for i in SPLIT_COUNT:
		var b = spawn_scene.instantiate()
		b.position = position + Vector2.from_angle(randf() * TAU) * 10.0
		b.scale = Vector2.ONE * SPLIT_SCALE
		b.immune_until = Time.get_ticks_msec() + 450
		parent.add_child.call_deferred(b)
