extends Building

# ============================================
# MINE STATS
# ============================================

var mine_health: int = randi_range(180, 220)
var mine_max_health: int = mine_health

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "Mine"
	type = "Mine"
	
	# Apply mine stats
	health = mine_health
	max_health = mine_max_health
	
	add_to_group("mines")
	super._ready()
