extends Node2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@export var bug_scene: PackedScene
@export var charger_scene: PackedScene
@export var splitter_scene: PackedScene

const START_INTERVAL : float = 2.0
const MIN_INTERVAL : float = 0.35
const RAMP_PER_SECOND : float = 0.02    # how fast spawning speeds up
const SPAWN_DISTANCE : float = 650.0    # must be larger than half your visible screen

var elapsed : float = 0.0
var cooldown : float = 1.0

func _ready() -> void:
	audio_stream_player.play()

func _process(delta: float) -> void:
	elapsed += delta
	cooldown -= delta
	if cooldown <= 0.0:
		spawn()
		cooldown = max(MIN_INTERVAL, START_INTERVAL - elapsed * RAMP_PER_SECOND)

func pick_scene() -> PackedScene:
	var roll : float = randf()
	if elapsed > 40.0 and charger_scene != null and roll < 0.15:
		return charger_scene
	if elapsed > 20.0 and splitter_scene != null and roll > 0.80:
		return splitter_scene
	return bug_scene

func spawn() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var enemy = pick_scene().instantiate()
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * SPAWN_DISTANCE
	get_tree().current_scene.add_child(enemy)
	print("new enemy spawned")
