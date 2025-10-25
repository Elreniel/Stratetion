extends Unit

func _ready():
	animated_sprite = $LancerSprite
	collision_shape = $CollisionShape2D
	
	type = "Lancer"
	health = 120
	attack_damage = 18
	movement_speed = 55.0
	
	center_position = global_position
	
	super._ready()
