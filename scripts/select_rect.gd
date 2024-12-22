extends Line2D

signal selected_units(Array)

@export var rel_width: float = 2.0

var _selection_rect: Rect2i = Rect2i(0,0,0,0)

var active: bool = false
func _set_active(a: bool) -> void:
	if a:
		_selection_rect.size = Vector2i.ZERO
		visible = true
	else:
		visible = false
	active = a

func _ready():
	%Camera.zoom_change.connect(self._on_zoom_change)
	%Select.cell_clicked.connect(self._on_cell_clicked)
	%Select.cell_released.connect(self._on_cell_released)
	%Select.cell_hovered.connect(self._on_cell_hovered)

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
	for unit: PlayerUnit in get_tree().get_nodes_in_group("player_units"):
		if r.has_point(unit.cell_position):
			ret.append(unit)
	return ret

func _on_cell_clicked(cell: Vector2i) -> void:
	if !active:
		return
	visible = true
	_selection_rect = Rect2i(cell, Vector2i.ZERO)
	_draw_select_rect()

func _on_cell_released(_cell: Vector2i) -> void:
	if !active:
		return
	visible = false
	var units = _get_selected_units()
	if units:
		selected_units.emit(units)

func _on_cell_hovered(cell: Vector2i) -> void:
	_selection_rect.end = cell
	_draw_select_rect()
