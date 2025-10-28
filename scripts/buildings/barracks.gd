extends Building

# ============================================
# BARRACKS STATS
# ============================================

var barracks_health: int = randi_range(270, 330)
var barracks_max_health: int = barracks_health

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "Barracks"
	type = "Barracks"
	
	# Apply barracks stats
	health = barracks_health
	max_health = barracks_max_health
	
	add_to_group("barracks")
	super._ready()
