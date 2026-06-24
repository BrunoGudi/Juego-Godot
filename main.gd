extends Node2D

# Cargamos la escena de la vela
@export var vela_scene: PackedScene = preload("res://vela.tscn")

# Número de velas que queremos colocar aleatoriamente en el mapa
@export var cantidad_velas: int = 20

func _ready() -> void:
	# Esperamos un frame para asegurarnos de que el TileMap esté completamente cargado
	await get_tree().process_frame
	generar_velas_aleatorias()

func generar_velas_aleatorias() -> void:
	# 1. Buscamos el nodo de tu mapa
	var tilemap: TileMapLayer = $TileMapLayer
	if not tilemap:
		print("Error: No se encontró el nodo TileMapLayer")
		return
		
	# 2. Obtenemos las coordenadas de todas las casillas dibujadas
	var todas_las_celdas = tilemap.get_used_cells()
	var celdas_suelo: Array[Vector2i] = []
	
	# Obtenemos la cantidad de capas físicas del TileSet para evitar errores si no hay ninguna
	var physics_layers_count = 0
	if tilemap.tile_set:
		physics_layers_count = tilemap.tile_set.get_physics_layers_count()
	
	# 3. Filtramos para quedarnos SOLO con las casillas de suelo caminable (sin colisiones)
	for celda in todas_las_celdas:
		var tile_data = tilemap.get_cell_tile_data(celda)
		if tile_data:
			# Si no hay capas de física o la casilla no tiene colisiones en la capa 0, es suelo caminable
			if physics_layers_count == 0 or tile_data.get_collision_polygons_count(0) == 0:
				celdas_suelo.append(celda)
				
	# Si por algún motivo no detecta colisiones, usamos todas las casillas para evitar fallos
	if celdas_suelo.is_empty():
		celdas_suelo = todas_las_celdas

	# 4. Mezclamos la lista de casillas de forma aleatoria (barajar)
	celdas_suelo.shuffle()
	
	# 5. Colocamos las velas en las primeras N posiciones aleatorias
	var velas_a_colocar = min(cantidad_velas, celdas_suelo.size())
	for i in range(velas_a_colocar):
		var celda_elegida = celdas_suelo[i]
		
		# Convertimos la coordenada de la cuadrícula (ej: 5, 10) a píxeles del juego (ej: 160, 320)
		var posicion_mundo = tilemap.map_to_local(celda_elegida)
		
		# Instanciamos la vela y la añadimos a la escena
		var vela = vela_scene.instantiate()
		add_child(vela)
		vela.global_position = posicion_mundo
