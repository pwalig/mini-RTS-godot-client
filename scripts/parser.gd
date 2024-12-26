class_name Parser
extends Script

const end_msg = CONFIG.end_msg
const end_section = CONFIG.end_section
const end_subsection = CONFIG.end_subsection
const end_param = CONFIG.end_param

static func _parse_players_state(msg: String) -> Dictionary:
	var players_info = msg.split(end_section,false)
	
	if !players_info[0].is_valid_int():
		printerr("Invalid player count")
		return {}
	
	var player_c = int(players_info[0])
	
	if players_info.size() != player_c + 1:
		printerr("Player count different than data suggests")
		return {}
	
	var parsed = {}
	
	for p in range(1, players_info.size()):
		var p_info = players_info[p].split(end_subsection,false)
		var p_params = p_info[0].split(end_param,false)
		
		if p_params.size() != 2:
			printerr("Invalid player: %d" % p)
			return {}
		var p_name = p_params[0]
		if !p_params[1].is_valid_int():
			printerr("Invalid unit count: %s" % p_name)
			return {}
		var unit_c = int(p_params[1])
		
		if p_info.size() != unit_c + 1:
			printerr("Unit count different than data suggests: " % p_name)
			return {}
		
		var units = []
		for u in range(1, p_info.size()):
			var u_params = p_info[u].split(end_param,false)
			if u_params.size() != 4:
				printerr("Invalid unit: %s : %d" % [p_name, u])
				return {}
			for up in range(1,4):
				if !u_params[up].is_valid_int():
					printerr("Invalid unit parameter: %s : %d : %d" % [p_name, u, up])
					return {}
			units.append([
				u_params[0], #id
				int(u_params[1]), # xPos
				int(u_params[2]), # yPos
				int(u_params[3]), # hp
			])
			
		parsed[p_name] = units
	
	return parsed

static func _parse_resources_state(msg: String) -> Array:
	var resource_info = msg.split(end_section,false)
	if !resource_info[0].is_valid_int():
		printerr("Invalid resource count")
		return []
	var resource_c = int(resource_info[0])
	
	if resource_info.size() != resource_c + 1:
		printerr("Resource count different than data suggests")
		return []
		
	var parsed = []
	for r in range(1, resource_info.size()):
		var r_params = resource_info[r].split(end_param,false)
		if r_params.size() != 3:
			printerr("Invalid resource: %d" % r)
			return []
		for rp in range(3):
			if !r_params[rp].is_valid_int():
				printerr("Invalid resource parameter: %d : %d" % [r, rp])
				return []
		parsed.append([
			int(r_params[0]), # xPos
			int(r_params[1]), # yPos
			int(r_params[2]), # hp
		])
		
	return parsed

static func _parse_configuration(msg: String) -> Array:
	var params = msg.split(end_param,false)
	if params.size() != 10:
		printerr("Invalid configuration")
		return []
		
	var parsed = []
	for i in range(9):
		if !params[i].is_valid_int():
			printerr("Invalid configuration param: %d = %s" % [i, params[i]])
			return []
		parsed.append(int(params[i]))
	parsed.append(params[9])

	return parsed

static func _parse_str(msg: String) -> String:
	return msg

static func _parse_dig(msg: String) -> Array:
	var params = msg.split(end_param,false)
	if params.size() != 2:
		printerr("Invalid dig message")
		return []
	if !params[1].is_valid_int():
		printerr("Invalid resource hp left: %s" % params[1])
		return []

	return [
		params[0],
		int(params[1])
	]

static func _parse_moved(msg: String) -> Array:
	var params = msg.split(end_param,false)
	if params.size() != 3:
		printerr("Invalid moved message")
		return []
	if !params[1].is_valid_int() or !params[2].is_valid_int():
		printerr("Invalid move position: %s %s" % [params[1],params[2]])
		return []
	
	return [
		params[0],
		Vector2i(int(params[1]),int(params[2]))
	]

static func _parse_attack(msg: String) -> Array:
	var params = msg.split(end_param,false)
	if params.size() != 3:
		printerr("Invalid attack message")
		return []
	if !params[2].is_valid_int():
		printerr("Invalid attack hp left: %s" % params[2])
		return []
	return [
		params[0],
		params[1],
		int(params[2])
	]

static func _parse_unit(msg: String) -> Array:
	var params = msg.split(end_param,false)
	if params.size() != 4:
		printerr("Invalid new unit message")
		return []
		
	if !params[2].is_valid_int() or !params[3].is_valid_int():
		printerr("Invalid new unit position: %s %s" % [params[2],params[3]])
		return []
		
	return [
		params[0],
		params[1],
		Vector2i(int(params[2]),int(params[3]))
	]
	

static func _parse_field_resource(msg: String) -> Array:
	var params = msg.split(end_param,false)
	if params.size() != 3:
		printerr("Invalid new resource message")
		return []
	if !params[0].is_valid_int() or !params[1].is_valid_int():
		printerr("Invalid new resource position: %s %s" % [params[0],params[1]])
		return []
	if !params[2].is_valid_int():
		printerr("Invalid new resource hp: %s" % params[2])
		return []
	return [
		Vector2i(int(params[0]),int(params[1])),
		int(params[2])
	]

static var _handler_map: Dictionary = {
	Message.Type.CONFIGURATION: _parse_configuration,
	Message.Type.JOIN: _parse_str,
	Message.Type.LEFT: _parse_str,
	Message.Type.MOVE: _parse_moved,
	Message.Type.ATTACK: _parse_attack,
	Message.Type.DIG: _parse_dig,
	Message.Type.UNIT: _parse_unit,
	Message.Type.FIELD_RESOURCE: _parse_field_resource,
	Message.Type.PLAYERS_STATE: _parse_players_state,
	Message.Type.RESOURCES_STATE: _parse_resources_state
}

static func parse(msg: String) -> Array:
	var decoded: Array = Message.decode(msg)
	var type = decoded[0]
	if type == null:
		printerr("Invalid message")
		return []
	
	if _handler_map.has(type):
		var parsed = _handler_map[type].call(decoded[1])
		if !parsed:
			return []
		return [type, parsed]
	
	return [type]
