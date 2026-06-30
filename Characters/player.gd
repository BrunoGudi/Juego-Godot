extends character

@onready var ataque_area: Area2D = $AtaqueArea
@onready var salud_ui: Label = $CanvasLayer/SaludUI
@onready var game_over_panel: Control = $CanvasLayer/GameOverPanel
@onready var bonus_ui: Label = $CanvasLayer/BonusUI

var speed_boost_active: bool = false
var double_damage_active: bool = false

var timer_ui: Label = null
var tiempo_partida: float = 0.0

func _ready() -> void:
	max_speed = 130 
	super._ready()
	actualizar_ui_salud()
	actualizar_ui_bonus()
	
	if game_over_panel:
		game_over_panel.visible = false
		var boton = game_over_panel.find_child("BotonReiniciar")
		if boton:
			boton.pressed.connect(_on_restart_button_pressed)

	timer_ui = Label.new()
	timer_ui.name = "TimerUI"
	timer_ui.add_theme_font_size_override("font_size", 24)
	timer_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_ui.custom_minimum_size = Vector2(200, 30)
	timer_ui.position = Vector2(1060, 10)
	$CanvasLayer.add_child(timer_ui)
	actualizar_ui_timer()

func _process(delta: float) -> void:
	if current_health > 0:
		tiempo_partida += delta
		actualizar_ui_timer()

func actualizar_ui_timer() -> void:
	if timer_ui:
		var mins = int(tiempo_partida) / 60
		var secs = int(tiempo_partida) % 60
		timer_ui.text = "Tiempo: %02d:%02d" % [mins, secs]

func recibir_golpe(danio: int, origen_ataque: Vector2) -> void:
	if current_health <= 0:
		return
	super.recibir_golpe(danio, origen_ataque)
	actualizar_ui_salud()

func actualizar_ui_salud() -> void:
	if salud_ui:
		var texto_corazones = ""
		for i in range(current_health):
			texto_corazones += "❤️"
		salud_ui.text = texto_corazones

func get_input() -> void:
	mov_direction = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	if mov_direction.x > 0:
		animated_sprite.flip_h = false
	elif mov_direction.x < 0:
		animated_sprite.flip_h = true

func ejecutar_ataque() -> void:
	var colision = ataque_area.get_node("CollisionShape2D")
	if colision:
		colision.position = Vector2.ZERO

	var enemigo_cercano: Node2D = null
	var dist_minima: float = 999999.0
	
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

	var direccion_ataque = Vector2.RIGHT
	if enemigo_cercano:
		var dir_relativa = global_position.direction_to(enemigo_cercano.global_position)
		if abs(dir_relativa.x) > abs(dir_relativa.y):
			direccion_ataque = Vector2.RIGHT if dir_relativa.x > 0 else Vector2.LEFT
		else:
			direccion_ataque = Vector2.DOWN if dir_relativa.y > 0 else Vector2.UP
	else:
		if mov_direction != Vector2.ZERO:
			if abs(mov_direction.x) > abs(mov_direction.y):
				direccion_ataque = Vector2.RIGHT if mov_direction.x > 0 else Vector2.LEFT
			else:
				direccion_ataque = Vector2.DOWN if mov_direction.y > 0 else Vector2.UP
		else:
			direccion_ataque = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT

	var distancia_ataque = 25.0
	ataque_area.position = direccion_ataque * distancia_ataque
	
	if direccion_ataque.x != 0:
		ataque_area.rotation = 0.0
	else:
		ataque_area.rotation = deg_to_rad(90)

	if direccion_ataque == Vector2.LEFT:
		animated_sprite.flip_h = true
	elif direccion_ataque == Vector2.RIGHT:
		animated_sprite.flip_h = false

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = colision.shape
	query.transform = colision.global_transform
	query.collision_mask = ataque_area.collision_mask
	
	var resultados = space_state.intersect_shape(query)
	var danio_final = 2 if double_damage_active else 1
	
	var cuerpos_golpeados = []
	for res in resultados:
		var cuerpo = res.collider
		if cuerpo != self and not cuerpo in cuerpos_golpeados:
			cuerpos_golpeados.append(cuerpo)
			if cuerpo.has_method("take_damage"):
				cuerpo.take_damage(danio_final)

func actualizar_ui_bonus() -> void:
	if bonus_ui:
		var texto = ""
		if speed_boost_active:
			texto += "⚡ Veloz "
		if double_damage_active:
			texto += "⚔️ Daño x2 "
		bonus_ui.text = texto

func curar(cantidad: int) -> void:
	current_health = min(max_health, current_health + cantidad)
	actualizar_ui_salud()
	print("¡Jugador curado! Vida actual: ", current_health)

func aplicar_boost_velocidad() -> void:
	if not speed_boost_active:
		speed_boost_active = true
		max_speed += 60
		actualizar_ui_bonus()
		print("¡Boost de velocidad activo!")
		await get_tree().create_timer(7.0).timeout
		max_speed -= 60
		speed_boost_active = false
		actualizar_ui_bonus()

func aplicar_daño_doble() -> void:
	if not double_damage_active:
		double_damage_active = true
		actualizar_ui_bonus()
		print("¡Daño doble activo!")
		await get_tree().create_timer(7.0).timeout
		double_damage_active = false
		actualizar_ui_bonus()

func morir() -> void:
	set_physics_process(false)
	
	if has_node("FiniteStateMachine"):
		$FiniteStateMachine.set_physics_process(false)
		
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.5).timeout
		
	await get_tree().create_timer(1.0).timeout
	
	if game_over_panel:
		game_over_panel.visible = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
