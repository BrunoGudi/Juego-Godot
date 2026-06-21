extends Area2D

@export var speed: float = 120.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Conectamos automáticamente la señal de colisión por código
	body_entered.connect(_on_body_entered)

func lanzar(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Si choca con el jugador
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("recibir_golpe"):
			body.recibir_golpe(1, global_position) # Aplica 1 de daño y retroceso
		queue_free()
	# Si choca con una pared/bloque del mapa (que no sea el tirador ni otro enemigo)
	elif not body is character and not body.is_in_group("enemigo"):
		queue_free()
