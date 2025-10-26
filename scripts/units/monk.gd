extends Unit

var heal_amount: int = 30
var heal_range: float = 80.0
var heal_cooldown_time: float = 5.0
var can_heal: bool = true
var heal_timer: Timer = null

var ally_target = null

func _ready():
	animated_sprite = $MonkSprite
	collision_shape = $CollisionShape2D
	
	type = "Monk"
	
	# Monk stats - support, healing
	health = 90
	max_health = 90
	attack_damage = 8  # Lower damage since they're support
	movement_speed = 50.0
	attack_range = 45.0
	detection_range = 180.0
	attack_cooldown = 2.5
	
	lifespan_min = 100.0
	lifespan_max = 150.0
	
	center_position = global_position
	
	# Create heal timer
	create_heal_timer()
	
	super._ready()

func create_heal_timer():
	heal_timer = Timer.new()
	add_child(heal_timer)
	heal_timer.wait_time = heal_cooldown_time
	heal_timer.one_shot = true
	heal_timer.timeout.connect(_on_heal_cooldown_finished)

func _on_heal_cooldown_finished():
	can_heal = true

# Override the physics process to prioritize healing
func _physics_process(delta):
	# Priority 1: Healing allies
	if can_heal:
		var injured_ally = find_injured_ally()
		if injured_ally:
			heal_ally(injured_ally, delta)
			return
	
	# Priority 2: Combat with enemies
	if enemy_target and is_instance_valid(enemy_target):
		handle_combat(delta)
		return
	
	# Priority 3: Normal movement
	if is_moving and not is_attacking:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5:
			global_position += direction * movement_speed * delta
			
			if animated_sprite:
				if direction.x < 0:
					animated_sprite.flip_h = true
				else:
					animated_sprite.flip_h = false
		else:
			start_idle()

func find_injured_ally() -> Node:
	var all_units = get_tree().get_nodes_in_group("units")
	var most_injured = null
	var lowest_health_percent = 1.0
	
	for unit in all_units:
		if is_instance_valid(unit) and unit != self:
			# Use max_health if available
			var max_hp = unit.max_health if "max_health" in unit else 100
			var health_percent = float(unit.health) / float(max_hp)
			
			# Find units below 70% health
			if health_percent < 0.7:
				var distance = global_position.distance_to(unit.global_position)
				if distance <= heal_range and health_percent < lowest_health_percent:
					lowest_health_percent = health_percent
					most_injured = unit
	
	return most_injured

func perform_heal(target):
	if not can_heal:
		return
	
	can_heal = false
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("heal"):
		animated_sprite.play("heal")
	elif animated_sprite:
		animated_sprite.play("attack")
	
	# Use max_health if available
	var max_hp = target.max_health if "max_health" in target else 150
	target.health = min(target.health + heal_amount, max_hp)
	
	print(type + " heals " + target.type + " for " + str(heal_amount) + " HP! (Now: " + str(target.health) + "/" + str(max_hp) + ")")
	
	# Visual feedback - green flash
	if target.animated_sprite:
		target.animated_sprite.modulate = Color(0.5, 1.5, 0.5)
		await get_tree().create_timer(0.3).timeout
		target.animated_sprite.modulate = Color(1, 1, 1)
	
	heal_timer.start()
	
func heal_ally(ally, delta):
	var distance = global_position.distance_to(ally.global_position)
	
	# Ally too far, forget it
	if distance > heal_range * 1.5:
		ally_target = null
		return
	
	# Move toward ally
	if distance > heal_range * 0.5:  # Get close to heal
		var direction = (ally.global_position - global_position).normalized()
		global_position += direction * movement_speed * delta
		
		# Flip sprite
		if animated_sprite:
			if direction.x < 0:
				animated_sprite.flip_h = true
			else:
				animated_sprite.flip_h = false
			
			if animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.play("walk")
	else:
		# Close enough to heal
		perform_heal(ally)

func special_ability():
	# Heal self
	print("Monk uses Healing Prayer on self!")
	health = min(health + heal_amount, 90)
	print("Monk healed! Current health: " + str(health))
	
	# Visual feedback
	if animated_sprite:
		animated_sprite.modulate = Color(0.5, 1.5, 0.5)
		await get_tree().create_timer(0.3).timeout
		animated_sprite.modulate = Color(1, 1, 1)
