extends Node2D

@onready var astar = AStarGrid2D.new()

func setup_ground(boardX: int, boardY: int) -> void:
	for y in range(boardY):
		for x in range(boardX):
			$ground.set_cell(Vector2i(x,y), 0, Vector2i(0,0))
	astar.region = $ground.get_used_rect()
	astar.update()

func _update_resource(resource: Array) -> void:
	$resources.set_cell(Vector2i(resource[0], resource[1]), 1, Vector2i(0,0))

func _update_resources(resources: Array) -> void:
	$resources.clear()
	for resource in resources:
		_update_resource(resource)

func update_state(board_state: Dictionary) -> void:
	_update_resources(board_state["resources"])

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
