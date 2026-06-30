extends character

@export var min_distance: float = 200.0
@export var max_distance: float = 220.0

@export var projectile_scene: PackedScene = preload("res://roca.tscn")

var is_attacking: bool = false
var player: CharacterBody2D = null

func _init() -> void:
	max_speed = 60
	max_health = 3

func _ready() -> void:
	super._ready()
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		super._physics_process(delta)
		return

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if player and not is_attacking:
		var distance: float = global_position.distance_to(player.global_position)
		var direction: Vector2 = global_position.direction_to(player.global_position)
		
		if distance > max_distance:
			mov_direction = direction
		elif distance < min_distance:
			mov_direction = -direction
		else:
			mov_direction = Vector2.ZERO
			if attack_cooldown_timer <= 0.0:
				iniciar_ataque()

		if mov_direction != Vector2.ZERO:
			if mov_direction.x > 0:
				animated_sprite.flip_h = false
			elif mov_direction.x < 0:
				animated_sprite.flip_h = true
		else:
			var dir_al_jugador = global_position.direction_to(player.global_position)
			if dir_al_jugador.x > 0:
				animated_sprite.flip_h = false
			elif dir_al_jugador.x < 0:
				animated_sprite.flip_h = true
	else:
		mov_direction = Vector2.ZERO

	if not is_attacking:
		move()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * FRICTION)
		move_and_slide()

	if not is_attacking:
		if velocity.length() > 5.0:
			animated_sprite.play("Movimiento")
		else:
			animated_sprite.play("Quieto")

func iniciar_ataque() -> void:
	is_attacking = true
	mov_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	var dir_al_jugador = global_position.direction_to(player.global_position)
	if dir_al_jugador.x > 0:
		animated_sprite.flip_h = false
	elif dir_al_jugador.x < 0:
		animated_sprite.flip_h = true
		
	animated_sprite.play("Ataque")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "Ataque":
		is_attacking = false
		attack_cooldown_timer = attack_cooldown
		
		if player and projectile_scene:
			var roca = projectile_scene.instantiate()
			get_parent().add_child(roca)
			roca.global_position = global_position
			
			var dir_tiro = global_position.direction_to(player.global_position)
			roca.lanzar(dir_tiro)

func recibir_golpe(danio: int, origen_ataque: Vector2) -> void:
	is_attacking = false
	super.recibir_golpe(danio, origen_ataque)

func morir() -> void:
	set_physics_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")
		await animated_sprite.animation_finished
	else:
		await get_tree().process_frame
		
	queue_free()
