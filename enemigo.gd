extends CharacterBody2D

# Variables editables desde el Inspector
@export var speed: float = 100.0
@export var max_health: int = 3
var current_health: int

# Referencia al nodo de animación
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D = null

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if player:
		var direction: Vector2 = global_position.direction_to(player.global_position)
		velocity = direction * speed
		
		# 1. Voltear sprite horizontalmente según hacia dónde camine
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# 2. Controlar la animación según el movimiento
	if velocity.length() > 5.0:
		animated_sprite.play("Movimiento")
	else:
		animated_sprite.play("Quieto")

func take_damage(amount: int) -> void:
	current_health -= amount
	print("Enemigo dañado. Vida restante: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	print("El enemigo ha muerto")
	queue_free()
