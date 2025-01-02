class_name PlayerUnit
extends Unit

func set_owner_nick(nick: String) -> void:
	owner_nick = nick
	$OwnerNickLabel.text = nick
	var hue = (abs(hash(nick)) % 256) / 256.0
	self_modulate = Color.from_hsv(hue, 1.0, 1.0)
	material.set("shader_parameter/outline_color",Color.from_hsv(hue + 0.5, 1.0, 1.0))

enum Action{
	MOVE,
	ATTACK,
	MINE,
}

signal request_action(String,Array)

var _target: Array = []
var _current_path: Array = []

@onready var map: Map = get_tree().get_first_node_in_group("map")
@onready var resources: TileMapLayer = map.get_node("resources")

@export var selected: bool = false : set = _set_selected
func _set_selected(s: bool) -> void:
	if selected == s:
		return
	selected = s
	material.set("shader_parameter/selected",selected)
	if selected:
		add_to_group("selected_units")
	else:
		remove_from_group("selected_units")

@export var outline_width: float = 0.02

func _on_zoom_change(zoom: float):
	super(zoom)
	material.set("shader_parameter/outline_width",outline_width/zoom)
	$Path.width = clampi(int(5/zoom), 10, 50)

func set_target_cell(cell: Vector2i) -> void:
	selected = false
	_current_path.clear()
	# check if attack unit
	if map.pos_unit_map.has(cell):
		var target_unit = map.pos_unit_map.get(cell)
		if target_unit.is_in_group("player_units"):
			_target = [Action.MOVE, cell] # we don't want friendly fire
		else:
			_target = [Action.ATTACK, target_unit]
		
	# check if mine resource
	elif resources.get_cell_source_id(cell) != -1:
		_target = [Action.MINE, cell]
	
	# else move
	else:
		_target = [Action.MOVE, cell]
	
	request_next_action()

func _recalculate_path() -> void:
	if !_target:
		_current_path.clear()
		return
	var target_cell: Vector2i
	if _target[0] == Action.ATTACK:
		if !is_instance_valid(_target[1]):
			return
		target_cell = _target[1].cell_position
	else:
		target_cell = _target[1]
	
	if !map.astar.is_in_boundsv(target_cell):
		printerr("Astar target cell out of bounds")
		return
		
	var target_is_solid: bool = map.astar.is_point_solid(target_cell)
	if target_is_solid:
		if cell_position.distance_to(target_cell) <= 1:
			_current_path.clear()
			return
		map.astar.set_point_solid(target_cell, false)
	
	var path: PackedVector2Array = map.astar.get_point_path(cell_position, target_cell, true)
	if target_is_solid:
		map.astar.set_point_solid(target_cell, true)
	
	if !path:
		_current_path.clear()
	_current_path = Array(path.slice(1))
	#print(cell_position, _current_path)

func _get_display_next_path_point() -> Vector2i:
	if _current_path.is_empty():
		_recalculate_path()
		if _current_path.is_empty():
			return cell_position
			
	var next_cell: Vector2i = _current_path.front()
	if next_cell == cell_position:
		_current_path.pop_front()
		if _current_path.is_empty():
			return cell_position
		next_cell = _current_path.front()
	if map.astar.is_point_solid(next_cell):
		_recalculate_path()
		if _current_path.is_empty():
			return cell_position
		next_cell = _current_path.front()
		
	$Path.add_point(Vector2(cell_position)*CONFIG.tilesize)
	for point in _current_path:
		$Path.add_point(point*CONFIG.tilesize)
	return next_cell

func _calculate_next_action() -> Array:
	if !_target:
		return []
	$Path.clear_points()
	match _target[0]:
		Action.MOVE:
			if cell_position == _target[1]:
				_target.clear()
				return []
			var cell = _get_display_next_path_point()
			return [Action.MOVE, cell_position, cell]
		Action.MINE:
			if cell_position == _target[1]:
				if resources.get_cell_source_id(cell_position) == -1:
					_target.clear()
					return []
				return [Action.MINE, cell_position]
			var cell = _get_display_next_path_point()
			return [Action.MOVE, cell_position, cell]
		Action.ATTACK:
			if !is_instance_valid(_target[1]):
				_target.clear()
				return []
			if cell_position.distance_to(_target[1].cell_position) <= 1.0:
				return [Action.ATTACK, cell_position, _target[1].cell_position]
			_current_path.clear()
			var cell = _get_display_next_path_point()
			return [Action.MOVE, cell_position, cell]
	
	return []

func request_next_action() -> void:
	var action = _calculate_next_action()
	if action:
		if action[0] != Action.MOVE or action[2] != cell_position:
			request_action.emit(str(name),action)
