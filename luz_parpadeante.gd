extends PointLight2D

# Configuración del parpadeo
@export var energia_base: float = 1.0
@export var velocidad_parpadeo: float = 6.0
@export var intensidad_variacion: float = 0.15

var tiempo: float = 0.0

func _process(delta: float) -> void:
	tiempo += delta * velocidad_parpadeo
	
	# Usamos una función seno combinada con algo de ruido aleatorio para simular el fuego
	var variacion = sin(tiempo) * intensidad_variacion + randf_range(-0.03, 0.03)
	energy = energia_base + variacion
