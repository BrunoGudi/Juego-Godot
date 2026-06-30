extends Area2D

@export var speed: float = 120.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func lanzar(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("recibir_golpe"):
			body.recibir_golpe(1, global_position)
		queue_free()
	elif not body is character and not body.is_in_group("enemigo"):
		queue_free()
