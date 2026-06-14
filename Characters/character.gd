extends CharacterBody2D
class_name character

const FRICTION: float = 0.15

@export var acceleration: int = 40
@export var max_speed: int = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var mov_direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Dejamos este bloque vacío. Todo lo va a controlar la FSM llamando a move()
	pass
	
func move() -> void:
	# Si hay input, aceleramos progresivamente hacia esa dirección
	if mov_direction != Vector2.ZERO:
		mov_direction = mov_direction.normalized()
		velocity += mov_direction * acceleration
		velocity = velocity.limit_length(max_speed)
	else:
		# Si soltaste las teclas, aplicamos la fricción matemática hacia el cero absoluto
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * FRICTION)
	
	# Ejecutamos el movimiento físico real en el mapa
	move_and_slide()
