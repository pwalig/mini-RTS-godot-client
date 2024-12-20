extends Node2D

@onready var astar = AStarGrid2D.new()

var trail_s = preload("res://scenes/select_trail.tscn")
var hovered_cell = Vector2i(-1,-1)

var unit_s = preload("res://scenes/unit.tscn")
var player_nick: String = ""

var _units_selected: bool = false
var _selection_rect: Rect2i = Rect2i(0,0,0,0)

func setup_ground(boardX: int, boardY: int) -> void:
	for y in range(boardY):
		for x in range(boardX):
			$ground.set_cell(Vector2i(x,y), 0, Vector2i(0,0))
	astar.region = $ground.get_used_rect()
	astar.update()

func _update_resource(resource: Array) -> void:
	$resources.set_cell(Vector2i(resource[0], resource[1]), 1, Vector2i(0,0))

func update_resources(resources: Array) -> void:
	$resources.clear()
	for resource in resources:
		_update_resource(resource)

func update_players(players: Dictionary) -> void:
	for player in players.keys():
		for unit_data in players[player]:
			var pos = Vector2i(unit_data[1], unit_data[2])
			var unit_id = player + unit_data[0]
			var unit: Unit = $units.get_node_or_null(unit_id)
			if unit == null:
				unit = unit_s.instantiate()
				unit.name = unit_id
				unit.owner_nick = player
				$units.add_child(unit)
				if player == player_nick: # unit belongs to local player
					if get_tree().get_node_count_in_group("player_units") == 0:
						%Camera.position = CONFIG.tilesize * Vector2(pos)
					unit.add_to_group("player_units")
			unit.cell_position = pos
			unit.hp = unit_data[3]
			unit.keep_alive = true
	
	for unit: Unit in $units.get_children():
		unit.die_if_should()

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

func _get_mouse_cell() -> Vector2i:
	return $ground.local_to_map(get_local_mouse_position())

func _get_units_by_rect(rect: Rect2i) -> Array:
	var r = rect.abs().grow_individual(0,0,1,1)
	var ret = []
	for unit: Unit in get_tree().get_nodes_in_group("player_units"):
		if r.has_point(unit.cell_position):
			ret.append(unit)
	return ret

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("main_click"):
			var cell_pos = _get_mouse_cell()
			if !_units_selected:
				_selection_rect = Rect2i(cell_pos, Vector2i.ZERO)
				%SelectRect.draw_select_rect(_selection_rect)
				%SelectRect.visible = true
				print("pressed")
				
		elif event.is_action_released("main_click"):
			%SelectRect.visible = false
			var cell_pos = _get_mouse_cell()
			print(_selection_rect)
			print(_get_units_by_rect(_selection_rect))
			return
	elif event is InputEventMouseMotion:
		var cell_pos = _get_mouse_cell()
		if hovered_cell == cell_pos:
			return
		hovered_cell = cell_pos
		var trail = trail_s.instantiate()
		trail.position = %Select.position
		$selection.add_child(trail)
		%Select.position = Vector2(hovered_cell) * CONFIG.tilesize
		
		_selection_rect.end = cell_pos
		%SelectRect.draw_select_rect(_selection_rect)
