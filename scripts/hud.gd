extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel

func _ready() -> void:
	ScoreManager.reset()
	ScoreManager.score_changed.connect(_on_score)
	ScoreManager.combo_changed.connect(_on_combo)
	ScoreManager.kill_scored.connect(_on_kill)

func _on_score(score: int) -> void:
	score_label.text = "SCORE %d" % score
	score_label.pivot_offset = score_label.size / 2.0
	score_label.scale = Vector2(1.4, 1.4)                       # punch on every kill
	create_tween().tween_property(score_label, "scale", Vector2.ONE, 0.15)

func _on_combo(combo: int) -> void:
	combo_label.visible = combo > 1
	combo_label.text = "COMBO x%d" % combo

func _on_kill(points: int, pos: Vector2) -> void:
	# floating "+10" that rises from the dead bug
	var popup := Label.new()
	popup.text = "+%d" % points
	popup.global_position = pos
	popup.z_index = 10
	get_tree().current_scene.add_child(popup)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(popup, "global_position:y", pos.y - 40.0, 0.6)
	tw.tween_property(popup, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(popup.queue_free)
