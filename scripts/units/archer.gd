extends Unit

func _ready():
	animated_sprite = $ArcherSprite
	collision_shape = $CollisionShape2D
	
	type = "Archer"
	
	# Archer stats - long range, fast attacks
	health = 70
	attack_damage = 15
	movement_speed = 60.0
	attack_range = 100.0  # Archers have longer range!
	detection_range = 300.0
	attack_cooldown = 0.8  # Fast attacks
	
	lifespan_min = 60.0
	lifespan_max = 90.0
	
	center_position = global_position
	
	super._ready()
