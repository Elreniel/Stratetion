extends Building

func _ready():
	building_type = "Mine"
	type = "Mine"
	health = 200
	max_health = 200
	add_to_group("mines")
	super._ready()
