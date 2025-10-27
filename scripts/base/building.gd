class_name Building
extends StaticBody2D

var building_type: String = "Building"
var type: String = "Building"  # For compatibility with attack system
var is_occupied: bool = false
var occupants: Array = []
var max_occupants: int = 10

# Building health
var health: int = 200
var max_health: int = 200

func _ready():
	add_to_group("buildings")
	print(building_type + " created with " + str(health) + " health")

func take_damage(amount: int):
	health -= amount
	print(building_type + " took " + str(amount) + " damage! Health: " + str(health) + "/" + str(max_health))
	
	# Visual feedback - flash red
	modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		on_destroyed()

func on_destroyed():
	print(building_type + " destroyed!")
	queue_free()

# Optional: Can place here logic
func can_place_here(position: Vector2) -> bool:
	return true
