extends Building

# ============================================
# MONASTERY STATS
# ============================================

var monastery_health: int = randi_range(225, 275)
var monastery_max_health: int = monastery_health

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "Monastery"
	type = "Monastery"
	
	# Apply monastery stats
	health = monastery_health
	max_health = monastery_max_health
	
	add_to_group("monastery")
	super._ready()
