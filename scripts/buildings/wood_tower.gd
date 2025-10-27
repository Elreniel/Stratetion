extends Building

func _ready():
	building_type = "Tower"
	type = "Tower"
	health = 500  # Towers are stronger
	max_health = 500
	
	add_to_group("towers")
	super._ready()
