extends Area2D

@export var flower_textures : Array[Texture2D]

@onready var sprite: Sprite2D = $Sprite2D

const HEAL_AMOUNT : float = 25.0

var collected : bool = false

func _ready() -> void:
	if not flower_textures.is_empty():
		sprite.texture = flower_textures.pick_random()
	body_entered.connect(_on_body_entered)
	# pop-in animation
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.has_method("heal"):
		return
	if body.heal(HEAL_AMOUNT):   # heal() returns false if the frog is already at full health
		collected = true
		set_deferred("monitoring", false)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		tw.chain().tween_callback(queue_free)
