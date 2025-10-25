extends Unit

func _ready():
	animated_sprite = $MonkSprite
	collision_shape = $CollisionShape2D
	
	type = "Monk"
	health = 100
	attack_damage = 12
	movement_speed = 50.0
	
	center_position = global_position
	
	super._ready()
