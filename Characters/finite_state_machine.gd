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

	match state:
		states.quieto:
			parent.velocity = lerp(parent.velocity, Vector2.ZERO, parent.FRICTION)
			parent.move_and_slide()
		states.movimiento:
			parent.move()
		states.retroceso:
			retroceso_timer -= delta
			parent.velocity = parent.velocity.move_toward(Vector2.ZERO, parent.max_speed * parent.FRICTION)
			parent.move_and_slide()
		states.atacar:
			ataque_timer -= delta
			parent.move()

func _get_transition() -> int:
	match state:
		states.quieto:
			if Input.is_action_just_pressed("attack"):
				return states.atacar
			if parent.mov_direction != Vector2.ZERO:
				return states.movimiento
		states.movimiento:
			if Input.is_action_just_pressed("attack"):
				return states.atacar
			if parent.mov_direction == Vector2.ZERO:
				return states.quieto
		states.retroceso:
			if retroceso_timer <= 0:
				if parent.mov_direction != Vector2.ZERO:
					return states.movimiento
				else:
					return states.quieto
		states.atacar:
			if ataque_timer <= 0:
				if parent.mov_direction != Vector2.ZERO:
					return states.movimiento
				else:
					return states.quieto
	return -1

func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.quieto:
			parent.animated_sprite.play("Quieto")
		states.movimiento:
			parent.animated_sprite.play("Movimiento")
		states.retroceso:
			parent.animated_sprite.play("Hurt")
			parent.velocity = parent.knockback_velocity
		states.atacar:
			ataque_timer = ATAQUE_DURACION
			parent.animated_sprite.play("Ataque")
			parent.ejecutar_ataque()
