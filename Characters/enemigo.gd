extends character # Ahora hereda de la clase base 'character'

var is_attacking: bool = false
var player: CharacterBody2D = null

func _ready() -> void:
	super._ready() # Inicializa salud usando la clase base
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Si el enemigo está en retroceso, dejamos que la clase base maneje esa física
	if knockback_timer > 0.0:
		super._physics_process(delta)
		return

	# Decrementar el tiempo de recarga
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if player and not is_attacking:
		var distance = global_position.distance_to(player.global_position)
		
		# Si estamos a rango de ataque y no está en cooldown, atacamos
		if distance <= attack_range and attack_cooldown_timer <= 0.0:
			iniciar_ataque()
		else:
			# Si no estamos atacando, nos movemos hacia el jugador
			mov_direction = global_position.direction_to(player.global_position)
			
			# Control de orientación (voltear sprite usando el animated_sprite heredado)
			if mov_direction.x > 0:
				animated_sprite.flip_h = false
			elif mov_direction.x < 0:
				animated_sprite.flip_h = true
	else:
		# Si no hay jugador o estamos atacando, no nos movemos voluntariamente
		mov_direction = Vector2.ZERO

	# Llamamos a la función de movimiento física heredada de 'character'
	if not is_attacking:
		move()
	else:
		# Si estamos atacando nos quedamos quietos pero seguimos aplicando fricción
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * FRICTION)
		move_and_slide()

	# Control de animación si no está en medio de un ataque
	if not is_attacking:
		if velocity.length() > 5.0:
			animated_sprite.play("Movimiento")
		else:
			animated_sprite.play("Quieto")

func iniciar_ataque() -> void:
	is_attacking = true
	# Detener movimiento físico
	mov_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# Asegurar que miramos al jugador al iniciar el ataque
	var dir_al_jugador = global_position.direction_to(player.global_position)
	if dir_al_jugador.x > 0:
		animated_sprite.flip_h = false
	elif dir_al_jugador.x < 0:
		animated_sprite.flip_h = true
		
	# Reproducir animación de Ataque
	animated_sprite.play("Ataque")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "Ataque":
		is_attacking = false
		attack_cooldown_timer = attack_cooldown
		
		# Al terminar la animación, verificamos si el jugador sigue a rango
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_range:
				# Hacemos daño y aplicamos el retroceso pasándole nuestra posición
				if player.has_method("recibir_golpe"):
					player.recibir_golpe(1, global_position)

func recibir_golpe(danio: int, origen_ataque: Vector2) -> void:
	is_attacking = false
	super.recibir_golpe(danio, origen_ataque)

func morir() -> void:
	# 1. Desactivamos el procesamiento físico para que deje de perseguir al jugador
	set_physics_process(false)
	
	# 2. Desactivamos sus colisiones para que no estorbe ni siga bloqueando el paso
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	# 3. Reproducimos la animación "Die" y esperamos a que termine
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")
		await animated_sprite.animation_finished # Espera a que termine la animación
	else:
		# Si por algún motivo no existe la animación, esperamos un cuadro
		await get_tree().process_frame
		
	# 4. Eliminamos finalmente al enemigo del juego
	queue_free()
