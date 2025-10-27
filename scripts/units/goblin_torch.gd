extends Enemy

func _ready():
	# Set sprite reference (adjust node name to match your scene)
	animated_sprite = $GoblinTorchSprite
	collision_shape = $GoblinTorchCollision
	
	# Goblin stats
	type = "Goblin"
	health = 75
	max_health = 75
	attack_damage = 15
	movement_speed = 50.0
	attack_range = 50.0
	detection_range = 250.0
	attack_cooldown = 1.5
	
	lifespan_min = 200.0
	lifespan_max = 300.0
	
	# Add to goblin-specific group
	add_to_group("goblins")
	
	# Call parent _ready()
	super._ready()
