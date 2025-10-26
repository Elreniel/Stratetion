extends Enemy

func _ready():
	# Set sprite reference (adjust node name to match your scene)
	animated_sprite = $GoblinTorchSprite
	collision_shape = $GoblinTorchCollision
	
	# Goblin stats
	type = "Goblin"
	health = 150
	max_health = 150
	attack_damage = 25
	movement_speed = 40.0
	attack_range = 40.0
	detection_range = 300.0
	attack_cooldown = 1.5
	
	lifespan_min = 120.0
	lifespan_max = 180.0
	
	# Add to goblin-specific group
	add_to_group("goblins")
	
	# Call parent _ready()
	super._ready()
