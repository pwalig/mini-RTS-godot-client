extends Node2D

@onready var astar = AStarGrid2D.new()

var unit_s = preload("res://scenes/unit.tscn")
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
			var pos = Vector2(unit_data[1], unit_data[2])
			var unit: Unit = $units.get_node_or_null(unit_data[0])
			if unit == null:
				unit = unit_s.instantiate()
				unit.name = unit_data[0]
				unit.owner_nick = player
				$units.add_child(unit)
				if player == player_nick: # unit belongs to local player
					if get_tree().get_node_count_in_group("player_units") == 0:
						%Camera.position = CONFIG.tilesize * pos
					unit.add_to_group("player_units")
			unit.cell_position = pos
			unit.hp = unit_data[3]
			unit.keep_alive = true
	
	for unit: Unit in $units.get_children():
		unit.die_if_should()

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
