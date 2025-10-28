extends Building

# ============================================
# CASTLE STATS
# ============================================

var castle_health: int = randi_range(900, 1100)
var castle_max_health: int = castle_health

# Castle-specific settings
var critical_health_threshold: float = 0.3

# ============================================
# SIGNALS
# ============================================

signal castle_destroyed

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	building_type = "Castle"
	type = "Castle"
	
	# Apply castle stats
	health = castle_health
	max_health = castle_max_health
	
	add_to_group("castle")
	super._ready()

# ============================================
# COMBAT (OVERRIDDEN)
# ============================================

func take_damage(amount: int):
	health -= amount
	print("🏰 CASTLE took " + str(amount) + " damage! Health: " + str(health) + "/" + str(max_health))
	
	# Visual feedback - flash red (using 0.2 for castle, longer than default 0.1)
	modulate = damage_flash_color
	await get_tree().create_timer(0.2).timeout
	modulate = normal_color
	
	# Warning when castle health is low
	if health <= max_health * critical_health_threshold and health > 0:
		print("⚠️ WARNING: Castle health critical!")
	
	if health <= 0:
		on_destroyed()

func on_destroyed():
	print("💀 CASTLE DESTROYED!")
	castle_destroyed.emit()
	
	# Don't queue_free immediately, let game handle it
	# queue_free()
