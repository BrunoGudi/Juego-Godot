extends Area2D

enum BonusType { VELOCITY, DOUBLE_DAMAGE, HEAL }
@export var tipo_bonus: BonusType = BonusType.HEAL

func _ready() -> void:
	var label = $Label as Label
	if label:
		match tipo_bonus:
			BonusType.VELOCITY:
				label.text = "⚡"
			BonusType.DOUBLE_DAMAGE:
				label.text = "⚔️"
			BonusType.HEAL:
				label.text = "❤️"

	# Conectar señal de colisión
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		match tipo_bonus:
			BonusType.VELOCITY:
				if body.has_method("aplicar_boost_velocidad"):
					body.aplicar_boost_velocidad()
			BonusType.DOUBLE_DAMAGE:
				if body.has_method("aplicar_daño_doble"):
					body.aplicar_daño_doble()
			BonusType.HEAL:
				if body.has_method("curar"):
					body.curar(1)
		
		queue_free()
