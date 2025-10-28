extends Building

# ============================================
# HOUSE STATS
# ============================================

var house_health: int = randi_range(135, 165)
var house_max_health: int = house_health
var house_max_occupants: int = randi_range(8, 12)

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "House"
	type = "House"
	
	# Apply house stats
	health = house_health
	max_health = house_max_health
	max_occupants = house_max_occupants
	
	add_to_group("houses")
	super._ready()

# ============================================
# HOUSE-SPECIFIC FUNCTIONS
# ============================================

func add_family(unit1, unit2):
	if occupants.size() + 2 <= max_occupants:
		occupants.append(unit1)
		occupants.append(unit2)
		is_occupied = true
