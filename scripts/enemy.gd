extends CharacterBody2D

@onready var player = get_node("/root/game/Player")
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D


var health = 30
var speed = 200.0

func _ready() -> void:
	pass



func _physics_process(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	#if Global.score > 3500:
		#speed = 300.0
	#if Global.score > 6500:
		#speed = 350.0
	#if Global.score > 8500:
		#speed = 400.0

func die():
	queue_free()

func take_damage():
	health = health - 1
	%Slime.play_hurt()
	
	if health <= 0:
		die()
