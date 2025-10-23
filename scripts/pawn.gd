extends Area2D

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func on_interact():
	print("You clicked on the Pawn!")
	# Add pawn interaction logic here later
	# For example: select the pawn, give it commands, etc.

func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2)  # Brighten

func _on_mouse_exited():
	modulate = Color(1, 1, 1)  # Normal color
