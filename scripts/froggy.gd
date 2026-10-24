extends CharacterBody2D

signal player_died

@onready var animated_sprite_2d: AnimatedSprite2D = $Sprite2D

@onready var hurt_area: Area2D = $HurtArea

@onready var weapon: Node2D = $Weapon

var player_health : float = 100.0

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

func _physics_process(delta: float) -> void:
	if dash_timer == 0.0:
		var input : Vector2 = Vector2(Input.get_axis("move_left" , "move_right") , Input.get_axis("move_up" , "move_down")).normalized()
		
		var velocity_weight_x : float = 1.0 - exp( - (acceleration if input.x else friction) * delta)
		velocity.x = lerp(velocity.x , input.x * max_speed , velocity_weight_x)
		
		var velocity_weight_y : float = 1.0 - exp( - (acceleration if input.y else friction) * delta)
		velocity.y = lerp(velocity.y , input.y * max_speed , velocity_weight_y)
		
		if input.x:
			animated_sprite_2d.flip_h = true if input.x < 0 else false
	
		#if input:
			#animated_sprite_2d.play("walk")
		#else:
			#animated_sprite_2d.play("idle")
	
	dash_logic(delta)
	move_and_slide()
	
	if Input.is_action_just_pressed("attack"):
		weapon.swing()
	
	const DAMAGE_RATE = 30.0
	var overlapping_mobs = hurt_area.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		player_health = player_health - DAMAGE_RATE * overlapping_mobs.size() * delta
		#HealthBar.value = player_health
		if player_health <= 0.0:
			player_died.emit()




func dash_logic(delta : float) -> void:
	if can_dash and Input.is_action_just_pressed("dash"):
		can_dash = false
		dash_timer = dash_time
		dash_reload_timer = dash_reload_cost
		
		dash_dir = global_position.direction_to(get_global_mouse_position())
		velocity = dash_dir * dash_speed
		#animated_sprite_2d.play("lunge")
		
		if dash_dir.x:
			animated_sprite_2d.flip_h = true if dash_dir.x < 0 else false
	
	if dash_timer > 0.0:
		dash_timer = max(0.0 , dash_timer - delta)
	else:
		if dash_reload_timer > 0.0:
			dash_reload_timer -= delta
		else:
			can_dash = true
