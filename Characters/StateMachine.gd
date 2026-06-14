extends Node
class_name FiniteStateMachine

var states: Dictionary = {}
var previous_state: int = -1

# Variable privada que guarda el valor real del estado
var _current_state: int = -1

# La variable pública usa el setter llamando a nuestra función segura
var state: int = -1:
	set(value):
		set_state(value)
	get:
		return _current_state

@onready var parent: character = get_parent()
@onready var animation_player: AnimationPlayer = parent.get_node("AnimationPlayer")


func _physics_process(delta: float) -> void:
	if _current_state != -1:
		_state_logic(delta)
		var transition: int = _get_transition()
		if transition != -1:
			set_state(transition)


func _state_logic(_delta: float) -> void:
	parent.get_input() # Lee las teclas del jugador y actualiza parent.mov_direction
	parent.move()      # Calcula la física de movimiento/frenado y desplaza el cuerpo

func _get_transition() -> int:
	match state:
		states.quieto:
			# Si el jugador empieza a presionar una tecla de dirección, pasamos a movimiento
			if parent.mov_direction != Vector2.ZERO:
				return states.movimiento
		states.movimiento:
			# Si soltó las teclas Y el personaje se desaceleró casi por completo
			if parent.mov_direction == Vector2.ZERO and parent.velocity.length() < 10:
				return states.quieto
	return -1

func _add_state(new_state: String) -> void:
	states[new_state] = states.size()

# Esta función ahora cambia de estado de forma segura sin recursión
func set_state(new_state: int) -> void:
	if new_state == _current_state: 
		return # Evita re-entrar al mismo estado
		
	_exit_state(_current_state)
	previous_state = _current_state
	_current_state = new_state
	_enter_state(previous_state, _current_state)


func _enter_state(_previous_state: int, _new_state: int) -> void:
	pass


func _exit_state(_state_exited: int) -> void:
	pass
