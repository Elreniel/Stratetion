extends Unit

func _ready():
	animated_sprite = $ArcherSprite
	collision_shape = $CollisionShape2D
	
	type = "Archer"
	health = 80  # Archers have less health
	attack_damage = 15
	movement_speed = 60.0  # Archers are faster
	
	center_position = global_position
	
	super._ready()
