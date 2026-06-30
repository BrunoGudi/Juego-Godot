extends Node2D

@export var vela_scene: PackedScene = preload("res://vela.tscn")
@export var cantidad_velas: int = 20

func _ready() -> void:
	await get_tree().process_frame
	generar_velas_aleatorias()

func generar_velas_aleatorias() -> void:
	var tilemap: TileMapLayer = $TileMapLayer
	if not tilemap:
		print("Error: No se encontró el nodo TileMapLayer")
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
				celdas_suelo.append(celda)
				
	if celdas_suelo.is_empty():
		celdas_suelo = todas_las_celdas

	celdas_suelo.shuffle()
	
	var velas_a_colocar = min(cantidad_velas, celdas_suelo.size())
	for i in range(velas_a_colocar):
		var celda_elegida = celdas_suelo[i]
		var posicion_mundo = tilemap.map_to_local(celda_elegida)
		
		var vela = vela_scene.instantiate()
		add_child(vela)
		vela.global_position = posicion_mundo
