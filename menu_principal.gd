extends Control

# Función que se llamará al pulsar el botón
func _on_boton_new_game_pressed() -> void:
	# Carga la escena del nivel principal
	get_tree().change_scene_to_file("res://main.tscn")
