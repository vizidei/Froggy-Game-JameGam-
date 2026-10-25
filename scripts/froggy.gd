extends CharacterBody2D

signal player_died

@export var dash_sounds : Array[AudioStream]

@onready var dash: AudioStreamPlayer = $Dash
@onready var splash: AudioStreamPlayer2D = $Splash
@onready var water_loop: AudioStreamPlayer2D = $WaterLoop

@onready var health_bar: ProgressBar = $"../HUD/HealthBar"



@onready var camera_2d: Camera2D = $Camera2D

const DASH_ZOOM_OUT : float = 0.85          # multiplier; smaller = zooms out more
var base_zoom : Vector2
var base_scale : Vector2
var anim_time : float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $Sprite2D

var facing: String = "front"
var move_input: Vector2 = Vector2.ZERO

@onready var hurt_area: Area2D = $HurtArea
@onready var feet_area: Area2D = $FeetArea

@onready var weapon: Node2D = $Weapon

const MAX_HEALTH : float = 100.0
var player_health : float = 100.0
var is_dead : bool = false

#Water attributes
const WATER_SLOW : float = 0.35     # speed multiplier in water (0.15 = your 85% slowdown)
const WATER_DPS : float = 8.0       # damage per second in water
var in_water : bool = false


const SHAKE_DECAY : float = 40.0     # how fast the shake fades (pixels per second)
const SWING_SHAKE : float = 8.0
const SWING_SPIN : float = TAU       # one full turn; try PI for a half-twist
const SWING_SPIN_TIME : float = 1.0

var shake_strength : float = 0.0
var swing_spin : float = 0.0
var juice_rot : float = 0.0
var spin_tween : Tween

#Movement Attributes
const max_speed : float = 100.0
const acceleration : float = 30.5
const friction : float = 22.0
var direction : Vector2

#Dash Attributes
const dash_speed : float = 300.0
const dash_time : float = 0.3
var can_dash : bool = true
var dash_timer : float = 0.0
var dash_dir : Vector2 = Vector2.ZERO
const dash_reload_cost : float = 0.5
var dash_reload_timer : float = 0.0

func _ready() -> void:
	base_zoom = camera_2d.zoom
	base_scale = animated_sprite_2d.scale

func update_juice(delta: float) -> void:
	
	const JUMP_SPRITE_OFFSET : float = PI / 2.0
	
	anim_time += delta
	var dashing : bool = dash_timer > 0.0
	var moving : bool = velocity.length() > 5.0 and not dashing

	var target_rot : float = 0.0
	var target_scale : Vector2 = base_scale

	if dashing:
		target_rot = dash_dir.angle() + JUMP_SPRITE_OFFSET
	elif moving:
		# little left-right waddle
		target_rot = sin(anim_time * 14.0) * 0.15
	elif not dashing:
		# idle breathing squish
		var breath : float = sin(anim_time * 3.0)
		target_scale = base_scale * Vector2(1.0 + breath * 0.03, 1.0 - breath * 0.03)

	var t : float = 1.0 - exp(-15.0 * delta)
	juice_rot = lerp_angle(juice_rot, target_rot, t)
	animated_sprite_2d.rotation = juice_rot + swing_spin
	#animated_sprite_2d.rotation = lerp_angle(animated_sprite_2d.rotation, target_rot, t)
	animated_sprite_2d.scale = animated_sprite_2d.scale.lerp(target_scale, t)

	# camera: zooms out quickly on dash, eases back slowly
	var target_zoom : Vector2 = base_zoom * DASH_ZOOM_OUT if dashing else base_zoom
	var zoom_speed : float = 10.0 if dashing else 3.0
	camera_2d.zoom = camera_2d.zoom.lerp(target_zoom, 1.0 - exp(-zoom_speed * delta))
	
	shake_strength = move_toward(shake_strength, 0.0, SHAKE_DECAY * delta)
	camera_2d.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	update_water_state()
	var speed_mult : float = WATER_SLOW if in_water else 1.0
	if dash_timer == 0.0:
		move_input = Vector2(Input.get_axis("move_left" , "move_right") , Input.get_axis("move_up" , "move_down")).normalized()
		
		var velocity_weight_x : float = 1.0 - exp( - (acceleration if move_input.x else friction) * delta)
		velocity.x = lerp(velocity.x , move_input.x * max_speed * speed_mult , velocity_weight_x)
		
		var velocity_weight_y : float = 1.0 - exp( - (acceleration if move_input.y else friction) * delta)
		velocity.y = lerp(velocity.y , move_input.y * max_speed * speed_mult , velocity_weight_y)
		
		#if input:
			#animated_animated_sprite_2d.play("walk")
		#else:
			#animated_animated_sprite_2d.play("idle")
	
	if Input.is_action_just_pressed("attack"):
		weapon.swing()
	
	dash_logic(delta)
	update_sprite()
	move_and_slide()
	check_damage(delta)
	update_juice(delta)

func add_shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)

func heal(amount: float) -> bool:
	if is_dead or player_health >= MAX_HEALTH:
		return false
	player_health = min(player_health + amount, MAX_HEALTH)
	return true

func check_damage(delta : float) -> void:
	const DAMAGE_RATE = 30.0
	var overlapping_mobs = hurt_area.get_overlapping_bodies()
	var damage : float = DAMAGE_RATE * overlapping_mobs.size() * delta
	if in_water:
		damage += WATER_DPS * delta
	if damage > 0.0:
		player_health -= damage
		print(str(player_health))
		if player_health <= 0.0:
			is_dead = true
			water_loop.stop()
			player_died.emit()
	
	health_bar.value = player_health

func dash_logic(delta : float) -> void:
	if can_dash and Input.is_action_just_pressed("dash"):
		can_dash = false
		dash_timer = dash_time
		dash_reload_timer = dash_reload_cost
		
		dash_dir = global_position.direction_to(get_global_mouse_position())
		velocity = dash_dir * dash_speed
		play_dash_sound()
	
	if dash_timer > 0.0:
		dash_timer = max(0.0 , dash_timer - delta)
	else:
		if dash_reload_timer > 0.0:
			dash_reload_timer -= delta
		else:
			can_dash = true

func update_sprite() -> void:
	# dashing: show the jump sprite, flipped toward the dash direction
	if dash_timer > 0.0:
		animated_sprite_2d.play("jump")
		animated_sprite_2d.flip_h = false
		return

	# walking: pick the sprite from the dominant axis
	if move_input != Vector2.ZERO and in_water == false:
		if abs(move_input.x) > abs(move_input.y):
			facing = "side"
			animated_sprite_2d.flip_h = move_input.x < 0.0
		else:
			facing = "back" if move_input.y < 0.0 else "front"
			animated_sprite_2d.flip_h = false

	if in_water:
		animated_sprite_2d.play("in_water")
	else:
		# when standing still, `facing` keeps the last direction
		animated_sprite_2d.play(facing)

func update_water_state() -> void:
	var was_in_water : bool = in_water
	in_water = dash_timer == 0.0 and feet_area.get_overlapping_areas().is_empty()

	if in_water and not was_in_water:
		splash.play()
		water_loop.play()
	elif not in_water and was_in_water:
		water_loop.stop()

func kick_cursor() -> void:
	var vp := get_viewport()
	var mouse : Vector2 = vp.get_mouse_position()
	var frog_screen : Vector2 = get_global_transform_with_canvas().origin
	# rotate the cursor around the frog, so it keeps its distance but changes its angle
	var new_pos : Vector2 = frog_screen + (mouse - frog_screen).rotated(randf_range(PI / 6.0, PI / 3.0) * (1 if randf() > 0.5 else -1))
	new_pos = new_pos.clamp(Vector2.ZERO, vp.get_visible_rect().size - Vector2.ONE)
	Input.warp_mouse(new_pos)

func _on_weapon_swung() -> void:
	kick_cursor()
	add_shake(SWING_SHAKE)
	if spin_tween:
		spin_tween.kill()
	swing_spin = 0.0
	spin_tween = create_tween()
	spin_tween.tween_property(self, "swing_spin", SWING_SPIN, SWING_SPIN_TIME)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spin_tween.tween_callback(func(): swing_spin = 0.0)


func play_dash_sound() -> void:
	if dash_sounds.is_empty():
		return
	dash.stream = dash_sounds.pick_random()
	dash.volume_db =randf_range(-5 , -3)
	dash.pitch_scale = randf_range(0.95, 1.05)   # small variation so repeats don't sound identical
	dash.play()
