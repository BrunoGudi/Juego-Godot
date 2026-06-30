extends Node2D

@export var bonus_scene: PackedScene = preload("res://bonus.tscn")

@onready var tilemap: TileMapLayer = $"../TileMapLayer"

var spawn_timer: float = 0.0
var spawn_interval: float = 12.0
var max_bonus: int = 4

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player or not is_instance_valid(player):
		return
	if player.has_node("CanvasLayer/GameOverPanel") and player.get_node("CanvasLayer/GameOverPanel").visible:
		return
		
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		var bonus_activos = get_tree().get_nodes_in_group("bonus").size()
		if bonus_activos < max_bonus:
			aparecer_bonus(player)

func aparecer_bonus(player: CharacterBody2D) -> void:
	if not tilemap or not bonus_scene:
		return
		
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
				if pos_global.x >= 48.0 and pos_global.x <= 1236.0 and pos_global.y >= 44.0 and pos_global.y <= 682.0:
					celdas_suelo.append(celda)

	if celdas_suelo.is_empty():
		return

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

	var bonus = bonus_scene.instantiate()
	
	var tipo_aleatorio = randi() % 3
	bonus.tipo_bonus = tipo_aleatorio
	
	get_parent().add_child(bonus)
	bonus.global_position = posicion_spawn
	
	bonus.add_to_group("bonus")
