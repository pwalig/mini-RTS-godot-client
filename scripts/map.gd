class_name Map
extends Node2D

@onready var astar = AStarGrid2D.new()

var unit_s = preload("res://scenes/unit.tscn")
var player_unit_s = preload("res://scenes/player_unit.tscn")
var player_nick: String = ""

var pos_unit_map: Dictionary = {}
var owner_unit_map: Dictionary = {}

var tick_moves_map: Dictionary = {}

func setup_ground() -> void:
	for y in range(CONFIG.boardXY.y):
		for x in range(CONFIG.boardXY.x):
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
			var unit_id = unit_data[0]
			var unit = $units.get_node_or_null(unit_id)
			if unit == null:
				spawn_unit(player, unit_id, pos)
			else:
				unit.cell_position = pos
				unit.hp = unit_data[3]

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

func spawn_unit(owner_nick: String, id: String, pos: Vector2i) -> void:
	if $units.get_node_or_null(id):
		printerr("Tried to spawn unit with existing id: %s" % id)
		return
	var unit
	if owner_nick == player_nick: # unit belongs to local player
		unit = player_unit_s.instantiate()
		if get_tree().get_node_count_in_group("player_units") == 0:
			%Camera.position = CONFIG.tilesize * Vector2(pos)
		unit.request_action.connect(get_parent()._on_unit_request_action)
	else:
		unit = unit_s.instantiate()
	unit.name = id
	unit.owner_nick = owner_nick
	unit.cell_position = pos
	$units.add_child(unit)
	
	pos_unit_map[pos] = unit
	owner_unit_map[owner_nick] = unit
	astar.set_point_solid(pos, true)

func spawn_unit_arr(msg: Array) -> void:
	spawn_unit(msg[0],msg[1],msg[2])

func spawn_resource(msg: Array) -> void:
	# resource hp = msg[1]
	$resources.set_cell(msg[0], 1, Vector2i.ZERO)

func _try_move_unit(id: String, pos: Vector2i) -> void:
	if pos_unit_map.has(pos):
		return
	var unit = $units.get_node_or_null(id)
	if !unit:
		return
	
	pos_unit_map[pos] = unit
	astar.set_point_solid(pos, true)
	$unit_markers.set_cell(pos, 2, Vector2i.ZERO)
	
	pos_unit_map.erase(unit.cell_position)
	astar.set_point_solid(unit.cell_position, false)
	$unit_markers.erase_cell(unit.cell_position)
	
	unit.cell_position = pos

func _kill_unit(unit: Unit) -> void:
	var pos: Vector2i = unit.cell_position
	owner_unit_map.erase(unit.owner_nick)
	pos_unit_map.erase(pos)
	astar.set_point_solid(pos, false)
	$unit_markers.erase_cell(pos)
	unit.die()

func queue_move_unit(msg: Array) -> void:
	tick_moves_map[msg[0]] = [Message.Type.MOVE, msg[1]]

func queue_mine_resource(msg: Array) -> void:
	tick_moves_map[msg[0]] = [Message.Type.DIG, msg[1]]

func queue_attack_unit(msg: Array) -> void:
	tick_moves_map[msg[0]] = [Message.Type.ATTACK, msg[1], msg[2]]

func commit_moves() -> void:
	for id in tick_moves_map:
		var type: Message.Type = tick_moves_map[id][0]
		match type:
			Message.Type.MOVE:
				_try_move_unit(id, tick_moves_map[id][1])
			Message.Type.DIG:
				var unit = $units.get_node_or_null(id)
				if unit:
					unit.call_deferred("mine")
					var hpLeft: int = tick_moves_map[id][1]
					if hpLeft <= 0:
						$resources.erase_cell(unit.cell_position)
			Message.Type.ATTACK:
				var attacker = $units.get_node_or_null(id)
				var attacked = $units.get_node_or_null(tick_moves_map[id][1])
				var hpLeft: int = tick_moves_map[id][2]
				if attacker:
					attacker.call_deferred("attack")
				if attacked:
					attacked.hp = hpLeft
					if hpLeft <= 0:
						_kill_unit(attacked)
	tick_moves_map.clear()
