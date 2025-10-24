extends StaticBody2D

# Add these variables to your house script
var is_occupied: bool = false
var occupants: Array = []

func _ready():
	add_to_group("houses")
