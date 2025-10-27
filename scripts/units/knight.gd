extends Unit

# Knight-specific behavior
var should_guard_home: bool = false  # Knights now patrol city

func _ready():
	animated_sprite = $KnightSprite
	collision_shape = $KnightCollision
	
	type = "Knight"
	
	# Knight stats - tank with high damage
	health = 150
	max_health = 150
	attack_damage = 25
	movement_speed = 40.0
	attack_range = 50.0
	detection_range = 250.0
	attack_cooldown = 1.2
	
	lifespan_min = 80.0
	lifespan_max = 120.0
	
	center_position = global_position
	
	# Call parent _ready() 
	super._ready()
	
	# Knights patrol the city instead of staying at one spot
	call_deferred("set_city_patrol_area")
	
	print("Knight ready to patrol city!")

func set_city_patrol_area():
	# Get city borders from main
	var main = get_parent()
	if main and main.has_method("get_city_patrol_position"):
		if main.city_initialized:
			# Set patrol area to city borders
			center_position = main.city_center
			circle_radius = max(
				main.city_border_right - main.city_border_left,
				main.city_border_bottom - main.city_border_top
			) / 2.0
			
			print("Knight patrolling city - Center: " + str(center_position) + " Radius: " + str(circle_radius))
			
			# Start patrolling
			pick_random_target()
		else:
			# City not initialized yet, use home position
			if home and is_instance_valid(home):
				center_position = home.global_position
				circle_radius = 200.0
			print("City not initialized, patrolling around home")
			pick_random_target()
	else:
		# Fallback to home position
		if home and is_instance_valid(home):
			center_position = home.global_position
			circle_radius = 200.0
		pick_random_target()
