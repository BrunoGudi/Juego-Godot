extends Node2D

@export var bonus_scene: PackedScene = preload("res://bonus.tscn")

@onready var tilemap: TileMapLayer = $"../TileMapLayer"

var spawn_timer: float = 0.0
var spawn_interval: float = 12.0 # Intenta spawnear un bonus cada 12 segundos
var max_bonus: int = 4            # Máximo de bonus activos a la vez en el mapa

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player or not is_instance_valid(player):
		return
	if player.has_node("CanvasLayer/GameOverPanel") and player.get_node("CanvasLayer/GameOverPanel").visible:
		return
		
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		# Contar cuántos bonus hay activos en el grupo "bonus"
		var bonus_activos = get_tree().get_nodes_in_group("bonus").size()
		if bonus_activos < max_bonus:
			aparecer_bonus(player)

func aparecer_bonus(player: CharacterBody2D) -> void:
	if not tilemap or not bonus_scene:
		return
		
	# 1. Obtener todas las celdas del suelo caminables
	var todas_las_celdas = tilemap.get_used_cells()
	var celdas_suelo: Array[Vector2i] = []

	for celda in todas_las_celdas:
		var tile_data = tilemap.get_cell_tile_data(celda)
		if tile_data and tile_data.get_collision_polygons_count(0) == 0:
			celdas_suelo.append(celda)

	if celdas_suelo.is_empty():
		return

	# 2. Buscar una posición aleatoria lejos del jugador (mínimo a 150 píxeles)
	celdas_suelo.shuffle()
	var posicion_spawn: Vector2 = Vector2.ZERO
	var encontrado: bool = false
	var distancia_minima: float = 150.0

	for celda in celdas_suelo:
		var pos_global = tilemap.global_position + tilemap.map_to_local(celda)
		if pos_global.distance_to(player.global_position) >= distancia_minima:
			posicion_spawn = pos_global
			encontrado = true
			break

	if not encontrado:
		var celda_azar = celdas_suelo[randi() % celdas_suelo.size()]
		posicion_spawn = tilemap.global_position + tilemap.map_to_local(celda_azar)

	# 3. Instanciar el bonus
	var bonus = bonus_scene.instantiate()
	
	# Cambiamos el tipo ANTES de meterlo a la escena (así _ready() lee el tipo correcto)
	var tipo_aleatorio = randi() % 3
	bonus.tipo_bonus = tipo_aleatorio
	
	# Ahora sí lo añadimos y posicionamos
	get_parent().add_child(bonus)
	bonus.global_position = posicion_spawn
	
	# Añadir al grupo "bonus" para llevar la cuenta
	bonus.add_to_group("bonus")
	print("¡Spawneado bonus tipo: ", tipo_aleatorio, " en ", posicion_spawn)
