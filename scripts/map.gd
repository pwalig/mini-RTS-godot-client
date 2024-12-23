class_name Map
extends Node2D

@onready var astar = AStarGrid2D.new()

var unit_s = preload("res://scenes/unit.tscn")
var player_unit_s = preload("res://scenes/player_unit.tscn")
var player_nick: String = ""

var unit_map: Dictionary = {}

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
			var unit = $units.get_node_or_null(unit_id)
			if unit == null:
				if player == player_nick: # unit belongs to local player
					unit = player_unit_s.instantiate()
					if get_tree().get_node_count_in_group("player_units") == 0:
						%Camera.position = CONFIG.tilesize * Vector2(pos)
					unit.add_to_group("player_units")
				else:
					unit = unit_s.instantiate()
				unit.name = unit_id
				unit.owner_nick = player
				$units.add_child(unit)
			unit.cell_position = pos
			unit.hp = unit_data[3]
			unit.keep_alive = true
	
	for unit: Unit in $units.get_children():
		unit.die_if_should()

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	%SelectRect.selected_units.connect(self._on_selected_units)
	%SelectRect.active = true

func _on_selected_units(units: Array) -> void:
	for unit: PlayerUnit in units:
		unit.selected = true
	%SelectRect.active = false
	%Select.cell_clicked.connect(self._on_selected_unit_action)
	%Select.cell_released.connect(self._on_ready_for_new_select)

func _on_selected_unit_action(cell: Vector2i) -> void:
	get_tree().call_group("selected_units", "set_target_cell", cell)
	%Select.cell_clicked.disconnect(self._on_selected_unit_action)

func _on_ready_for_new_select(_cell) -> void:
	%SelectRect.set_deferred("active", true)
	%Select.cell_released.disconnect(self._on_ready_for_new_select)

func spawn_unit(owner: String, id: String, pos: Vector2i) -> void:
	if $units.get_node_or_null(id):
		printerr("Tried to spawn node with existing id: %s" % id)
		return
	var unit
	if owner == player_nick: # unit belongs to local player
		unit = player_unit_s.instantiate()
		if get_tree().get_node_count_in_group("player_units") == 0:
			%Camera.position = CONFIG.tilesize * Vector2(pos)
		unit.request_action.connect(get_parent()._on_unit_request_action)
	else:
		unit = unit_s.instantiate()
	unit.name = id
	unit.owner_nick = owner
	unit.cell_position = pos
	$units.add_child(unit)
	
	unit_map[pos] = unit
	astar.set_point_solid(pos, true)

func try_move_unit(id: String, pos: Vector2i) -> void:
	if unit_map.has(pos):
		return
	var unit = $units.get_node_or_null(id)
	if !unit:
		return
	
	unit_map[pos] = unit
	astar.set_point_solid(pos, true)
	$unit_markers.set_cell(pos, 2, Vector2i.ZERO)
	
	unit_map.erase(unit.cell_position)
	astar.set_point_solid(unit.cell_position, false)
	$unit_markers.erase_cell(unit.cell_position)
	
	unit.cell_position = pos
