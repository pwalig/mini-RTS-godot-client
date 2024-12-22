extends Node2D

@onready var astar = AStarGrid2D.new()

var unit_s = preload("res://scenes/unit.tscn")
var player_unit_s = preload("res://scenes/player_unit.tscn")
var player_nick: String = ""

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
	print(units)
	for unit: PlayerUnit in units:
		unit.selected = true
	%SelectRect.active = false
