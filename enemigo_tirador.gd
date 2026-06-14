extends CharacterBody2D

# Parámetros editables desde el Inspector
@export var speed: float = 50.0
@export var min_distance: float = 200.0
@export var max_distance: float = 220.0

# Referencia al nodo de animación
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if player:
		var distance: float = global_position.distance_to(player.global_position)
		var direction: Vector2 = global_position.direction_to(player.global_position)
		
		if distance > max_distance:
			velocity = direction * speed
		elif distance < min_distance:
			velocity = -direction * speed
		else:
			velocity = Vector2.ZERO

				# 1. Control de orientación (voltear sprite)
		if velocity.x != 0:
			# Si se está moviendo (cazando o huyendo), mira hacia donde camina
			if velocity.x > 0:
				animated_sprite.flip_h = false
			elif velocity.x < 0:
				animated_sprite.flip_h = true
		else:
			# Si se detuvo, se da la vuelta para mirar/apuntar al jugador
			if direction.x > 0:
				animated_sprite.flip_h = false
			elif direction.x < 0:
				animated_sprite.flip_h = true


	move_and_slide()
	
	# 2. Controlar la animación según si se está moviendo físicamente o no
	if velocity.length() > 5.0:
		animated_sprite.play("Movimiento")
	else:
		animated_sprite.play("Quieto")
		
