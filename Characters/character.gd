extends CharacterBody2D
class_name character

const FRICTION: float = 0.15

@export var acceleration: int = 40
@export var max_speed: int = 100

@export var max_health: int = 5
var current_health: int

@export var knockback_duration: float = 0.25
@export var knockback_force_multiplier: float = 2.5
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

@export var attack_range: float = 35.0
@export var attack_cooldown: float = 1.5
var attack_cooldown_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var mov_direction: Vector2 = Vector2.ZERO
var base_max_speed: int = -1

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	if not has_node("FiniteStateMachine") and knockback_timer > 0.0:
		knockback_timer -= delta
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, max_speed * FRICTION)
		move_and_slide()
		if animated_sprite.sprite_frames.has_animation("Hurt"):
			animated_sprite.play("Hurt")

func move() -> void:
	if mov_direction != Vector2.ZERO:
		mov_direction = mov_direction.normalized()
		velocity += mov_direction * acceleration
		velocity = velocity.limit_length(max_speed)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * FRICTION)
	move_and_slide()

func recibir_golpe(danio: int, origen_ataque: Vector2) -> void:
	current_health = max(0, current_health - danio)
	print(name, " golpeado! Vida restante: ", current_health)
	
	var direccion_retroceso = (global_position - origen_ataque).normalized()
	if direccion_retroceso == Vector2.ZERO:
		direccion_retroceso = Vector2.UP
		
	var fuerza_retroceso = max_speed * knockback_force_multiplier
	knockback_velocity = direccion_retroceso * fuerza_retroceso
	knockback_timer = knockback_duration
	
	if has_node("FiniteStateMachine"):
		var fsm = $FiniteStateMachine
		if "states" in fsm and "retroceso" in fsm.states:
			fsm.retroceso_timer = knockback_duration
			fsm.set_state(fsm.states.retroceso)
			
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	
	if current_health <= 0:
		morir()

func take_damage(amount: int) -> void:
	var direccion_opuesta = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
	var origen = global_position - direccion_opuesta
	recibir_golpe(amount, origen)

func morir() -> void:
	queue_free()

func actualizar_velocidad(multiplier: float) -> void:
	if base_max_speed == -1:
		base_max_speed = max_speed
	max_speed = int(base_max_speed * multiplier)
