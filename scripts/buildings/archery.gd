extends Building

# ============================================
# ARCHERY STATS
# ============================================

var archery_health: int = randi_range(225, 275)
var archery_max_health: int = archery_health

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "Archery"
	type = "Archery"
	
	# Apply archery stats
	health = archery_health
	max_health = archery_max_health
	
	add_to_group("archery")
	super._ready()
