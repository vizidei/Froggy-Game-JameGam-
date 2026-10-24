extends Node2D

@onready var hit_box: Area2D = $HitBox

const SWING_ARC : float = PI      # 180 degrees
const SWING_TIME : float = 0.2

var swinging : bool = false
var hit_bodies : Array = []

func _process(delta: float) -> void:
	if swinging:
		return
	var target_angle : float = global_position.direction_to(get_global_mouse_position()).angle()
	# smooth follow; use "rotation = target_angle" instead for an instant snap
	rotation = lerp_angle(rotation, target_angle, 1.0 - exp(-25.0 * delta))

func swing() -> void:
	if swinging:
		return
	swinging = true
	hit_bodies.clear()

	var base_angle : float = rotation  # the weapon is already aiming at the mouse
	rotation = base_angle - SWING_ARC / 2.0
	hit_box.monitoring = true

	var tween := create_tween()
	tween.tween_property(self, "rotation", base_angle + SWING_ARC / 2.0, SWING_TIME)
	await tween.finished

	hit_box.monitoring = false
	swinging = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body in hit_bodies:
		return  # one hit per enemy per swing
	hit_bodies.append(body)
	if body.has_method("launch"):
		body.launch(global_position.direction_to(body.global_position))
