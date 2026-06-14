extends FiniteStateMachine

func _init() -> void:
	_add_state("quieto")
	_add_state("movimiento")

func _ready() -> void:
	await get_tree().process_frame
	set_state(states.quieto)
	
func _state_logic(_delta: float) -> void:
	parent.get_input()
	
	# Modificación lógica de fuerzas:
	match state:
		states.quieto:
			# Si está quieto, aplicamos el lerp de frenado continuo
			parent.velocity = lerp(parent.velocity, Vector2.ZERO, parent.FRICTION)
			parent.move_and_slide() # Mueve el cuerpo residual mientras se frena
		states.movimiento:
			# Si se está moviendo, llamamos a la función que le suma aceleración
			parent.move()

func _get_transition() -> int:
	match state:
		states.quieto:
			# Pasamos a movimiento inmediatamente si el jugador presiona cualquier tecla
			if parent.mov_direction != Vector2.ZERO:
				return states.movimiento
		states.movimiento:
			# Pasamos a quieto inmediatamente si el jugador deja de presionar teclas (o se cancelan)
			if parent.mov_direction == Vector2.ZERO:
				return states.quieto
	return -1

func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.quieto:
			# Reproduce la animación "quieto" directamente desde el AnimatedSprite2D del jugador
			parent.animated_sprite.play("Quieto")
		states.movimiento:
			# Reproduce la animación "movimiento" directamente
			parent.animated_sprite.play("Movimiento")
