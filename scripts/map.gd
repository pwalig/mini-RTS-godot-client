extends Node2D

@onready var astar = AStarGrid2D.new()

func setup_ground(boardX: int, boardY: int) -> void:
	for y in range(boardY):
		for x in range(boardX):
			$ground.set_cell(Vector2i(x,y), 0, Vector2i(0,0))
	astar.region = $ground.get_used_rect()
	astar.update()

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	$ground.set_cell(Vector2i(0,0), 0, Vector2i(0,0))
