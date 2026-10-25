extends Node2D

signal swung

@onready var swoosh_metal: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var swoosh: AudioStreamPlayer2D = $AudioStreamPlayer2D2

@onready var hit_box: Area2D = $HitBox
@onready var sprite_2d: Sprite2D = $Sprite2D

const DAMAGE : int = 30

const SWING_ARC : float = PI      # 180 degrees
const SWING_TIME : float = 0.2

var swinging : bool = false
var hit_bodies : Array = []

func _process(delta: float) -> void:
	update_visuals()
	if swinging:
		return
	var target_angle : float = global_position.direction_to(get_global_mouse_position()).angle()
	# smooth follow; use "rotation = target_angle" instead for an instant snap
	rotation = lerp_angle(rotation, target_angle, 1.0 - exp(-25.0 * delta))

func swing() -> void:
	if swinging:
		return
	swinging = true
	swung.emit()
	sfx()
	hit_bodies.clear()

func sfx() -> void:
	swoosh_metal.volume_db = randf_range(-25, -30)
	swoosh_metal.pitch_scale = randf_range(0.40, 0.70)
	swoosh.volume_db = randf_range(7.00, 9.00)
	swoosh.pitch_scale = randf_range(1.30, 1.55)
	swoosh.play()
	swoosh_metal.play()

	var base_angle : float = rotation  # the weapon is already aiming at the mouse
	rotation = base_angle - SWING_ARC / 2.0
	hit_box.monitoring = true

	var tween := create_tween()
	tween.tween_property(self, "rotation", base_angle + SWING_ARC / 2.0, SWING_TIME)
	await tween.finished

	hit_box.monitoring = false
	swinging = false

func update_visuals() -> void:
	# behind the frog when pointing up, in front otherwise
	z_index = -1 if sin(rotation) < 0.0 else 1
	# keep the weapon from looking upside down when pointing left
	#sprite_2d.scale.y = sprite_2d.scale.y * -1.0 if cos(rotation) < 0.0 else sprite_2d.scale.y

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body in hit_bodies:
		return  # one hit per enemy per swing
	hit_bodies.append(body)
	if body.has_method("take_damage") and swinging:
		body.take_damage(DAMAGE , global_position.direction_to(body.global_position))
	#if body.has_method("launch"):
		#body.launch(global_position.direction_to(body.global_position))
