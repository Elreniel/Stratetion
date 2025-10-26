extends Unit

func _ready():
	animated_sprite = $LancerSprite
	collision_shape = $CollisionShape2D
	
	type = "Lancer"
	
	# Lancer stats - medium range, good damage
	health = 110
	max_health = 110
	attack_damage = 20
	movement_speed = 55.0
	attack_range = 70.0  # Longer reach with lance
	detection_range = 220.0
	attack_cooldown = 1.5
	
	lifespan_min = 70.0
	lifespan_max = 100.0
	
	center_position = global_position
	
	super._ready()
