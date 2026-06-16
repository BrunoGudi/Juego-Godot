extends character # Ahora hereda de la clase base 'character'

# Conservamos solo las variables específicas de este enemigo
@export var max_health: int = 3
var current_health: int

var player: CharacterBody2D = null

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(_delta: float) -> void:
	if player:
		# En lugar de velocity, actualizamos la dirección de movimiento para la física heredada
		mov_direction = global_position.direction_to(player.global_position)
		
		# Control de orientación (voltear sprite usando el animated_sprite heredado)
		if mov_direction.x > 0:
			animated_sprite.flip_h = false
		elif mov_direction.x < 0:
			animated_sprite.flip_h = true
	else:
		mov_direction = Vector2.ZERO
		
	# Llamamos a la función de movimiento física heredada de 'character'
	move()
	
	# Control de animación
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
