extends Unit

func _ready():
	animated_sprite = $KnightSprite
	collision_shape = $CollisionShape2D
	
	type = "Knight"
	
	# Knight stats - tank with high damage
	health = 150
	max_health = 150
	attack_damage = 25
	movement_speed = 40.0
	attack_range = 50.0
	detection_range = 250.0
	attack_cooldown = 1.2
	
	lifespan_min = 80.0
	lifespan_max = 120.0
	
	center_position = global_position
	
	super._ready()
