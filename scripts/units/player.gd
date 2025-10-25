extends CharacterBody2D

const SPEED = 300.0
var selected_object = null

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite

func _physics_process(delta: float) -> void:
	
	var direction = Vector2.ZERO
	
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	if direction.x == 0 and direction.y == 0:
		player_sprite.play("idle")
	if direction.x > 0:
		player_sprite.play("walk")
		player_sprite.flip_h = false
	elif direction.x < 0:
		player_sprite.play("walk")
		player_sprite.flip_h = true
	elif direction.y > 0:
		player_sprite.play("walk_down")
	elif direction.y < 0:
		player_sprite.play("walk_up")
		
		
	velocity = direction * SPEED

	move_and_slide()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_mouse_click()

func handle_mouse_click():
	var world_click = get_global_mouse_position()
	
	# Check what we clicked on
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_click
	query.collide_with_areas = true
	
	var result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		var clicked_object = result[0].collider
		if clicked_object.is_in_group("interactable"):
			print("Clicked on: ", clicked_object.name)
			if clicked_object.has_method("on_interact"):
				clicked_object.on_interact()
			selected_object = clicked_object
	else:
		print("Clicked on empty space")
		selected_object = null
