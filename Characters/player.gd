extends character

func get_input() -> void:
	# 1. Obtenemos el vector de movimiento usando las acciones de tu Input Map
	mov_direction = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
		
	# 2. Controlamos el flip (giro horizontal) del sprite según la dirección en X
	if mov_direction.x > 0:
		animated_sprite.flip_h = false
	elif mov_direction.x < 0:
		animated_sprite.flip_h = true
