extends Control

signal building_selected(building_type: String)

var radius = 80.0

func _ready():
	custom_minimum_size = Vector2(300, 300)
	size = Vector2(300, 300)
	
	await get_tree().process_frame
	arrange_buttons_in_circle()
	connect_buttons()

func arrange_buttons_in_circle():
	var buttons = []
	
	# Add all buttons to the array
	if has_node("HouseButton"):
		buttons.append(get_node("HouseButton"))
	if has_node("BarrackButton"):
		buttons.append(get_node("BarrackButton"))
	if has_node("MineButton"):
		buttons.append(get_node("MineButton"))
	if has_node("ArcheryButton"):
		buttons.append(get_node("ArcheryButton"))
	if has_node("MonastryButton"):
		buttons.append(get_node("MonastryButton"))
	if has_node("TowerButton"):
		buttons.append(get_node("TowerButton"))
	if has_node("WoodTowerButton"):
		buttons.append(get_node("WoodTowerButton"))
	
	if buttons.is_empty():
		print("ERROR: No buttons found!")
		return
	
	var num_buttons = buttons.size()
	var center = Vector2(150, 150)
	
	for i in range(num_buttons):
		var angle = (TAU / num_buttons) * i - (PI / 2)
		var offset = Vector2(
			cos(angle) * radius,
			sin(angle) * radius
		)
		
		var button_size = buttons[i].custom_minimum_size
		if button_size == Vector2.ZERO:
			button_size = Vector2(80, 80)
		
		buttons[i].position = center + offset - button_size / 2

func connect_buttons():
	if has_node("HouseButton"):
		get_node("HouseButton").pressed.connect(_on_house_selected)
	if has_node("BarrackButton"):
		get_node("BarrackButton").pressed.connect(_on_barracks_selected)
	if has_node("MineButton"):
		get_node("MineButton").pressed.connect(_on_mine_selected)
	if has_node("ArcheryButton"):
		get_node("ArcheryButton").pressed.connect(_on_archery_selected)
	if has_node("MonastryButton"):
		get_node("MonastryButton").pressed.connect(_on_monastry_selected)
	if has_node("TowerButton"):
		get_node("TowerButton").pressed.connect(_on_tower_selected)
	if has_node("WoodTowerButton"):
		get_node("WoodTowerButton").pressed.connect(_on_wood_tower_selected)

func _on_house_selected():
	building_selected.emit("house")
	queue_free()

func _on_barracks_selected():
	building_selected.emit("barracks")
	queue_free()

func _on_mine_selected():
	building_selected.emit("mine")
	queue_free()

func _on_archery_selected():
	building_selected.emit("archery")
	queue_free()

func _on_monastry_selected():
	building_selected.emit("monastry")
	queue_free()

func _on_tower_selected():
	building_selected.emit("tower")
	queue_free()

func _on_wood_tower_selected():
	building_selected.emit("wood_tower")
	queue_free()
