extends Building

signal castle_destroyed

func _ready():
	building_type = "Castle"
	type = "Castle"
	health = 1000  # Castle has lots of health
	max_health = 1000
	
	add_to_group("castle")
	super._ready()

func take_damage(amount: int):
	health -= amount
	print("🏰 CASTLE took " + str(amount) + " damage! Health: " + str(health) + "/" + str(max_health))
	
	# Visual feedback - flash red
	modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)
	
	# Warning when castle health is low
	if health <= max_health * 0.3 and health > 0:
		print("⚠️ WARNING: Castle health critical!")
	
	if health <= 0:
		on_destroyed()

func on_destroyed():
	print("💀 CASTLE DESTROYED!")
	castle_destroyed.emit()
	
	# Don't queue_free immediately, let game handle it
	# queue_free()
