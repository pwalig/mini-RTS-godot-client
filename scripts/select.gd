extends Sprite2D

signal cell_clicked(Vector2i)
signal cell_released(Vector2i)
signal cell_hovered(Vector2i)

var trail_s = preload("res://scenes/select_trail.tscn")
var hovered_cell = Vector2i(-1,-1)

func _get_mouse_cell() -> Vector2i:
	return %ground.local_to_map(%ground.get_local_mouse_position())

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("main_click"):
			var cell_pos = _get_mouse_cell()
			cell_clicked.emit(cell_pos)
			
		elif event.is_action_released("main_click"):
			var cell_pos = _get_mouse_cell()
			cell_released.emit(cell_pos)
			
	elif event is InputEventMouseMotion:
		var cell_pos = _get_mouse_cell()
		if hovered_cell == cell_pos:
			return
		hovered_cell = cell_pos
		cell_hovered.emit(hovered_cell)
		
		var trail = trail_s.instantiate()
		trail.position = position
		add_sibling(trail)
		set_deferred("position", Vector2(hovered_cell) * CONFIG.tilesize)
