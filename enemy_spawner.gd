extends Node2D

@export var enemigo_comun: PackedScene = preload("res://Characters/Enemigo.tscn")
@export var enemigo_tirador: PackedScene = preload("res://Characters/EnemigoTirador.tscn")

@onready var tilemap: TileMapLayer = $"../TileMapLayer"

var tiempo_transcurrido: float = 0.0
var spawn_timer: float = 0.0

# Ajustes iniciales de dificultad
var spawn_interval_base: float = 5.0 # Frecuencia inicial de spawn (en segundos)
var max_enemigos: int = 15           # Límite máximo de enemigos activos a la vez

func _physics_process(delta: float) -> void:
	# Buscamos al jugador en el grupo "player"
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	# Si no hay jugador o está muerto (mostrando la pantalla de Game Over), no hacemos spawn
	if not player or not is_instance_valid(player):
		return
	if player.has_node("CanvasLayer/GameOverPanel") and player.get_node("CanvasLayer/GameOverPanel").visible:
		return

	tiempo_transcurrido += delta
	spawn_timer += delta

	# Aumentar dificultad: reducir el intervalo de tiempo entre spawns progresivamente
	# Cada 60 segundos restamos 0.5s al intervalo, hasta un límite mínimo de 0.7s
	var spawn_interval = max(0.7, spawn_interval_base - (tiempo_transcurrido / 60.0) * 0.5)

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		# Contar cuántos enemigos hay actualmente en el mapa
		var enemigos_actuales = get_tree().get_nodes_in_group("enemigo").size()
		if enemigos_actuales < max_enemigos:
			aparecer_enemigo(player)

func aparecer_enemigo(player: CharacterBody2D) -> void:
	if not tilemap:
		print("Error: No se encontró el TileMapLayer en el Spawner")
		return

	# 1. Obtener todas las celdas caminables del mapa
	var todas_las_celdas = tilemap.get_used_cells()
	var celdas_suelo: Array[Vector2i] = []

	var physics_layers_count = 0
	if tilemap.tile_set:
		physics_layers_count = tilemap.tile_set.get_physics_layers_count()

	for celda in todas_las_celdas:
		var tile_data = tilemap.get_cell_tile_data(celda)
		if tile_data:
			if physics_layers_count == 0 or tile_data.get_collision_polygons_count(0) == 0:
				var pos_global = tilemap.global_position + tilemap.map_to_local(celda)
				# NUEVO: Comprobar que esté dentro de los límites del cuadro jugable
				if pos_global.x >= 48.0 and pos_global.x <= 1236.0 and pos_global.y >= 44.0 and pos_global.y <= 682.0:
					celdas_suelo.append(celda)


	if celdas_suelo.is_empty():
		return

	# 2. Barajar celdas y buscar una alejada del jugador
	celdas_suelo.shuffle()
	var posicion_spawn: Vector2 = Vector2.ZERO
	var encontrado: bool = false
	var distancia_minima: float = 200.0

	for celda in celdas_suelo:
		var pos_global = tilemap.global_position + tilemap.map_to_local(celda)
		if pos_global.distance_to(player.global_position) >= distancia_minima:
			posicion_spawn = pos_global
			encontrado = true
			break

	# Si no se encontró un punto alejado, usamos uno aleatorio por seguridad
	if not encontrado:
		var celda_azar = celdas_suelo[randi() % celdas_suelo.size()]
		posicion_spawn = tilemap.global_position + tilemap.map_to_local(celda_azar)

	# 3. Determinar el tipo de enemigo a crear según el tiempo transcurrido
	var escena_a_instanciar = enemigo_comun
	var probabilidad_tirador = 0.0

	if tiempo_transcurrido > 120.0:     # Más de 2 minutos
		probabilidad_tirador = 0.45     # 45% probabilidad de tirador
	elif tiempo_transcurrido > 60.0:    # Más de 1 minuto
		probabilidad_tirador = 0.30     # 30% probabilidad de tirador
	elif tiempo_transcurrido > 30.0:    # Más de 30 segundos
		probabilidad_tirador = 0.15     # 15% probabilidad de tirador

	if randf() < probabilidad_tirador and enemigo_tirador:
		escena_a_instanciar = enemigo_tirador

	# 4. Instanciar y añadir a la escena principal
	var enemigo = escena_a_instanciar.instantiate()
	get_parent().add_child(enemigo)
	enemigo.global_position = posicion_spawn
	
	# Asegurarnos de que el enemigo esté en el grupo "enemigo" para contarlo
	if not enemigo.is_in_group("enemigo"):
		enemigo.add_to_group("enemigo")
