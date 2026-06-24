extends character

@onready var ataque_area: Area2D = $AtaqueArea
@onready var salud_ui: Label = $CanvasLayer/SaludUI
@onready var game_over_panel: Control = $CanvasLayer/GameOverPanel

func _ready() -> void:
	max_speed = 130 
	super._ready() # Inicializa current_health desde character.gd
	actualizar_ui_salud()
	
	# Asegurarnos de que el panel esté oculto al iniciar y conectar el botón
	if game_over_panel:
		game_over_panel.visible = false
		var boton = game_over_panel.find_child("BotonReiniciar")
		if boton:
			boton.pressed.connect(_on_restart_button_pressed)

var speed_boost_active: bool = false
var double_damage_active: bool = false


# Función para recibir golpes y refrescar la UI
func recibir_golpe(danio: int, origen_ataque: Vector2) -> void:
	print("¡El jugador recibió un golpe! Vida antes: ", current_health)
	super.recibir_golpe(danio, origen_ataque) # Ejecuta el retroceso y resta vida
	print("Vida después: ", current_health, " | SaludUI es nulo?: ", salud_ui == null)
	actualizar_ui_salud() # Actualiza los corazones en pantalla


# Dibuja tantos corazones como vida actual tenga el jugador
func actualizar_ui_salud() -> void:
	if salud_ui:
		var texto_corazones = ""
		for i in range(current_health):
			texto_corazones += "❤️"
		salud_ui.text = texto_corazones

func get_input() -> void:
	# 1. Obtenemos el vector de movimiento usando las acciones de tu Input Map
	mov_direction = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
		
	# 2. Controlamos el flip (giro horizontal) del sprite según la dirección en X
	if mov_direction.x > 0:
		animated_sprite.flip_h = false
	elif mov_direction.x < 0:
		animated_sprite.flip_h = true

func ejecutar_ataque() -> void:
	# 1. Centramos temporalmente la colisión para hacer los cálculos de distancia limpios
	var colision = ataque_area.get_node("CollisionShape2D")
	if colision:
		colision.position = Vector2.ZERO

	# 2. Buscamos al enemigo más cercano
	var enemigo_cercano: Node2D = null
	var dist_minima: float = 999999.0
	
	# Buscamos en el grupo "enemigo" o por tipo 'character' en el escenario
	var candidatos = get_tree().get_nodes_in_group("enemigo")
	if candidatos.is_empty():
		for hijo in get_parent().get_children():
			if hijo is character and hijo != self:
				candidatos.append(hijo)
				
	for nodo in candidatos:
		if is_instance_valid(nodo):
			var dist = global_position.distance_to(nodo.global_position)
			if dist < dist_minima:
				dist_minima = dist
				enemigo_cercano = nodo

	# 3. Determinamos la dirección en base al enemigo o movimiento del jugador
	var direccion_ataque = Vector2.RIGHT
	if enemigo_cercano:
		# Apuntar hacia el enemigo
		var dir_relativa = global_position.direction_to(enemigo_cercano.global_position)
		if abs(dir_relativa.x) > abs(dir_relativa.y):
			direccion_ataque = Vector2.RIGHT if dir_relativa.x > 0 else Vector2.LEFT
		else:
			direccion_ataque = Vector2.DOWN if dir_relativa.y > 0 else Vector2.UP
	else:
		# Si no hay enemigos cerca, atacamos en la dirección a la que nos estamos moviendo
		if mov_direction != Vector2.ZERO:
			if abs(mov_direction.x) > abs(mov_direction.y):
				direccion_ataque = Vector2.RIGHT if mov_direction.x > 0 else Vector2.LEFT
			else:
				direccion_ataque = Vector2.DOWN if mov_direction.y > 0 else Vector2.UP
		else:
			# Si estamos parados y no hay enemigos, usamos la orientación del sprite
			direccion_ataque = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT

	# 4. Ajustamos la posición y la rotación del AtaqueArea
	var distancia_ataque = 25.0 # Distancia desde el centro del jugador
	ataque_area.position = direccion_ataque * distancia_ataque
	
	# Si atacamos arriba/abajo, rotamos 90 grados la colisión rectangular para que sea vertical
	if direccion_ataque.x != 0:
		ataque_area.rotation = 0.0
	else:
		ataque_area.rotation = deg_to_rad(90)

	# 5. Forzamos la orientación visual del sprite según la dirección en X (para ataques izquierda/derecha)
	if direccion_ataque == Vector2.LEFT:
		animated_sprite.flip_h = true
	elif direccion_ataque == Vector2.RIGHT:
		animated_sprite.flip_h = false

	# 6. Detectamos colisiones y aplicamos daño
	var cuerpos = ataque_area.get_overlapping_bodies()
	var danio_final = 2 if double_damage_active else 1
	for cuerpo in cuerpos:
		if cuerpo != self and cuerpo.has_method("take_damage"):
			cuerpo.take_damage(danio_final)

# Recupera vida hasta el máximo de 5 corazones
func curar(cantidad: int) -> void:
	current_health = min(max_health, current_health + cantidad)
	actualizar_ui_salud()
	print("¡Jugador curado! Vida actual: ", current_health)

# Aumenta la velocidad en +60 por 7 segundos
func aplicar_boost_velocidad() -> void:
	if not speed_boost_active:
		speed_boost_active = true
		max_speed += 60
		print("¡Boost de velocidad activo!")
		await get_tree().create_timer(7.0).timeout
		max_speed -= 60
		speed_boost_active = false
		print("¡Boost de velocidad terminado!")

# Duplica el daño de los golpes por 7 segundos
func aplicar_daño_doble() -> void:
	if not double_damage_active:
		double_damage_active = true
		print("¡Daño doble activo!")
		await get_tree().create_timer(7.0).timeout
		double_damage_active = false
		print("¡Daño doble terminado!")


func morir() -> void:
	print("¡El jugador ha muerto! Fin del juego.")
	
	# 1. Desactivamos las físicas y los controles del jugador para que no pueda moverse
	set_physics_process(false)
	
	# 2. Apagamos la máquina de estados para evitar que interrumpa la animación de muerte
	if has_node("FiniteStateMachine"):
		$FiniteStateMachine.set_physics_process(false)
		
	# 3. Desactivamos las colisiones para que los enemigos no sigan chocando con el cuerpo
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	# 4. Reproducimos la animación "Die" y esperamos a que termine
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")
		await animated_sprite.animation_finished
	
	else:
		# Si aún no has creado la animación, espera un segundo y medio por seguridad
		await get_tree().create_timer(1.5).timeout
		
	# 5. Esperamos un segundo extra
	await get_tree().create_timer(1.0).timeout
	
	# 6. Mostramos el menú de Game Over
	if game_over_panel:
		game_over_panel.visible = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
