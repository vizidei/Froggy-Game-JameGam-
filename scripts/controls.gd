extends Control   # use whatever type your root node is (Control, CanvasLayer, Node2D...)

const GAME_SCENE : String = "res://scenes/main.tscn"  # change to your game scene's path
const INPUT_DELAY : float = 0.3

var can_start : bool = false

func _ready() -> void:
	# short delay so the key or click that opened this screen doesn't skip it
	await get_tree().create_timer(INPUT_DELAY).timeout
	can_start = true

func _input(event: InputEvent) -> void:
	if not can_start:
		return
	var is_press : bool = event.is_pressed() and not event.is_echo()
	var is_valid : bool = event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if is_press and is_valid:
		can_start = false   # stops a double trigger
		get_tree().change_scene_to_file(GAME_SCENE)
