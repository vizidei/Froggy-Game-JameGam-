extends Node2D

@onready var game_over: CanvasLayer = $GameOver
@onready var high_score_label: Label = $GameOver/ColorRect/HighScoreLabel

func _ready() -> void:
	game_over.hide()

func _on_froggy_player_died() -> void:
	get_tree().paused = true
	game_over.show()
	high_score_label.text = "Your score was: " + str(ScoreManager.score)
