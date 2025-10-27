extends Building

func _ready():
	building_type = "Archery"
	type = "Archery"
	health = 250
	max_health = 250
	
	add_to_group("archery")
	super._ready()
