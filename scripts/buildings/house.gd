extends Building

func _ready():
	building_type = "House"
	type = "House"
	max_occupants = 10
	health = 150
	max_health = 150
	
	add_to_group("houses")
	super._ready()

# House-specific functions
func add_family(unit1, unit2):
	if occupants.size() + 2 <= max_occupants:
		occupants.append(unit1)
		occupants.append(unit2)
		is_occupied = true
