extends Building

func _ready():
	building_type = "Monastry"
	type = "Monastry"
	health = 250
	max_health = 250
	
	add_to_group("monastry")
	super._ready()
