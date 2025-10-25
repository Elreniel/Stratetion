# In knight.gd
extends Unit

func _ready():
	animated_sprite = $KnightSprite
	type = "Knight"
	health = 150
	attack_damage = 20
	
	center_position = global_position
	
	super._ready()
