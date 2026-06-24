extends FiniteStateMachine

const RETROCESO_DURACION: float = 0.25
var retroceso_timer: float = 0.0
const ATAQUE_DURACION: float = 0.2
var ataque_timer: float = 0.0


func _init() -> void:
	_add_state("quieto")
	_add_state("movimiento")
	_add_state("retroceso")
	_add_state("atacar")

func _ready() -> void:
	await get_tree().process_frame
	set_state(states.quieto)
	
func _state_logic(delta: float) -> void:
	if state != states.retroceso:
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
		states.retroceso:
			retroceso_timer -= delta
			# Aplicamos fricción gradual para frenar el retroceso
			parent.velocity = parent.velocity.move_toward(Vector2.ZERO, parent.max_speed * parent.FRICTION)
			parent.move_and_slide()
		states.atacar:
			ataque_timer -= delta
			parent.move()


func _get_transition() -> int:
	match state:
		states.quieto:
			# NUEVO: Si presionamos click izquierdo, atacamos
			if Input.is_action_just_pressed("attack"):
				return states.atacar
			# Pasamos a movimiento inmediatamente si el jugador presiona cualquier tecla
			if parent.mov_direction != Vector2.ZERO:
				return states.movimiento
		states.movimiento:
			# NUEVO: Si presionamos click izquierdo, atacamos
			if Input.is_action_just_pressed("attack"):
				return states.atacar
			# Pasamos a quieto inmediatamente si el jugador deja de presionar teclas
			if parent.mov_direction == Vector2.ZERO:
				return states.quieto
		states.retroceso:
			# Pasamos a quieto o movimiento cuando termina el tiempo de retroceso
			if retroceso_timer <= 0:
				if parent.mov_direction != Vector2.ZERO:
					return states.movimiento
				else:
					return states.quieto
		states.atacar:
			# Al terminar la duración del golpe volvemos a movernos o quedar quietos
			if ataque_timer <= 0:
				if parent.mov_direction != Vector2.ZERO:
					return states.movimiento
				else:
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
		states.retroceso:
			# Reproduce la animación de recibir golpe
			parent.animated_sprite.play("Hurt")
			parent.velocity = parent.knockback_velocity
		states.atacar:
			ataque_timer = ATAQUE_DURACION
			parent.animated_sprite.play("Ataque")
			parent.ejecutar_ataque()
