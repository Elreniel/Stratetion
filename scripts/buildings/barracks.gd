extends Building

func _ready():
	building_type = "Barracks"
	type = "Barracks"
	health = 300
	max_health = 300
	
	add_to_group("barracks")
	super._ready()
