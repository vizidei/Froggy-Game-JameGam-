extends Node

signal score_changed(score: int)
signal combo_changed(combo: int)
signal kill_scored(points: int, pos: Vector2)

const BASE_POINTS : int = 10
const COMBO_WINDOW : float = 2.5   # seconds to land the next kill

var score : int = 0
var combo : int = 0
var combo_timer : float = 0.0

func reset() -> void:
	score = 0
	combo = 0
	combo_timer = 0.0
	score_changed.emit(score)
	combo_changed.emit(combo)

func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(combo)

func register_kill(pos: Vector2) -> void:
	combo += 1
	combo_timer = COMBO_WINDOW
	var multiplier : int = 1 + int(combo)  
	var points : int = BASE_POINTS * multiplier
	score += points
	score_changed.emit(score)
	combo_changed.emit(combo)
	kill_scored.emit(points, pos)
