extends Line2D

signal selected_units(Array)

@export var rel_width: float = 2.0

var trail_s = preload("res://scenes/select_trail.tscn")
var hovered_cell = Vector2i(-1,-1)

var _selection_rect: Rect2i = Rect2i(0,0,0,0)

var active: bool = false
func _set_active(a: bool) -> void:
	if a:
		var cell_pos = _get_mouse_cell()
		_selection_rect = Rect2i(cell_pos, Vector2i.ZERO)
		visible = true
	else:
		visible = false
	active = a

func _ready():
	%Camera.zoom_change.connect(self._on_zoom_change)

func _get_mouse_cell() -> Vector2i:
	return %ground.local_to_map(get_local_mouse_position())

func _on_zoom_change(zoom: float):
	width = rel_width / zoom

func _draw_select_rect() -> void:
	var rect = _selection_rect.abs()
	clear_points()
	add_point(Vector2(rect.position) * CONFIG.tilesize)
	add_point(Vector2(rect.end.x+1, rect.position.y) * CONFIG.tilesize)
	add_point((Vector2(rect.end)+Vector2.ONE) * CONFIG.tilesize)
	add_point(Vector2(rect.position.x, rect.end.y+1) * CONFIG.tilesize)

func _get_selected_units() -> Array:
	var r = _selection_rect.abs().grow_individual(0,0,1,1)
	var ret = []
	for unit: Unit in get_tree().get_nodes_in_group("player_units"):
		if r.has_point(unit.cell_position):
			ret.append(unit)
	return ret

func _input(event):
	if !active:
		return
	if event is InputEventMouseButton:
		if event.is_action_pressed("main_click"):
			var cell_pos = _get_mouse_cell()
			_selection_rect = Rect2i(cell_pos, Vector2i.ZERO)
			_draw_select_rect()
			visible = true
				
		elif event.is_action_released("main_click"):
			visible = false
			var units = _get_selected_units()
			if units:
				selected_units.emit(units)
			return
			
	elif event is InputEventMouseMotion:
		var cell_pos = _get_mouse_cell()
		if hovered_cell == cell_pos:
			return
		hovered_cell = cell_pos
		var trail = trail_s.instantiate()
		trail.position = %Select.position
		add_sibling(trail)
		%Select.position = Vector2(hovered_cell) * CONFIG.tilesize
		
		_selection_rect.end = cell_pos
		_draw_select_rect()
