extends Building

# ============================================
# TOWER STATS
# ============================================

var tower_health: int = randi_range(450, 550)
var tower_max_health: int = tower_health

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "Tower"
	type = "Tower"
	
	# Apply tower stats
	health = tower_health
	max_health = tower_max_health
	
	add_to_group("towers")
	super._ready()
