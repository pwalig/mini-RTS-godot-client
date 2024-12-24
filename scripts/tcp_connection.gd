extends Node

signal game_message(Array)
signal connection_result(bool)
signal error

@export var host: String = "127.0.0.1" : set = _set_host
@export var port: int = 1234 : set = _set_port

const end_msg = "\n"
const end_section = ";"
const end_subsection = ","
const end_param = " "

var _msg_queue: Array[PackedByteArray] = []

func _set_host(new_host: String) -> void:
	host = new_host
	print("Switched host to: %s" % host)

func _set_port(new_port: int) -> void:
	port = new_port
	print("Switched port to: %d" % port)

var _client = TCPClient.new()

func _on_connected() -> void:
	connection_result.emit(true)

func _on_disconnected() -> void:
	error.emit()

func _on_error(err: int) -> void:
	connection_result.emit(false)
	error.emit()

#func _parse_game_joined(msg: String) -> void:
	#var params = msg.split(end_param,false)
	#
	#if params.size() != 3:
		#printerr("Incorrect game joined message!")
		#return
		#
	#if !params[0].is_valid_int():
		#printerr("Incorrect boardX")
		#return
		#
	#if !params[1].is_valid_int():
		#printerr("Incorrect boardY")
		#return
		#
	#if !params[2].is_valid_int():
		#printerr("Incorrect unitsToWin")
		#return
#
	#game_message.emit([Message.Type.GAME_JOINED, [
		#int(params[0]), # boardX
		#int(params[1]), # boardY
		#int(params[2]), # unitsToWin
	#]])

func _parse_players_state(msg: String) -> void:
	var players_info = msg.split(end_section,false)
	
	if !players_info[0].is_valid_int():
		printerr("Invalid player count")
		return
	
	var player_c = int(players_info[0])
	
	if players_info.size() != player_c + 1:
		printerr("Player count different than data suggests")
		return
	
	var parsed = {}
	
	for p in range(1, players_info.size()):
		var p_info = players_info[p].split(end_subsection,false)
		var p_params = p_info[0].split(end_param,false)
		
		if p_params.size() != 2:
			printerr("Invalid player: %d" % p)
			return
		var p_name = p_params[0]
		if !p_params[1].is_valid_int():
			printerr("Invalid unit count: %s" % p_name)
			return
		var unit_c = int(p_params[1])
		
		if p_info.size() != unit_c + 1:
			printerr("Unit count different than data suggests: " % p_name)
			return
		
		var units = []
		for u in range(1, p_info.size()):
			var u_params = p_info[u].split(end_param,false)
			if u_params.size() != 4:
				printerr("Invalid unit: %s : %d" % [p_name, u])
				return
			for up in range(1,4):
				if !u_params[up].is_valid_int():
					printerr("Invalid unit parameter: %s : %d : %d" % [p_name, u, up])
					return
			units.append([
				u_params[0], #id
				int(u_params[1]), # xPos
				int(u_params[2]), # yPos
				int(u_params[3]), # hp
			])
			
		parsed[p_name] = units
	
	game_message.emit([Message.Type.PLAYERS_STATE, parsed])

func _parse_resources_state(msg: String) -> void:
	var resource_info = msg.split(end_section,false)
	if !resource_info[0].is_valid_int():
		printerr("Invalid resource count")
		return
	var resource_c = int(resource_info[0])
	
	if resource_info.size() != resource_c + 1:
		printerr("Resource count different than data suggests")
		return
		
	var parsed = []
	for r in range(1, resource_info.size()):
		var r_params = resource_info[r].split(end_param,false)
		if r_params.size() != 3:
			printerr("Invalid resource: %d" % r)
			return
		for rp in range(3):
			if !r_params[rp].is_valid_int():
				printerr("Invalid resource parameter: %d : %d" % [r, rp])
				return
		parsed.append([
			int(r_params[0]), # xPos
			int(r_params[1]), # yPos
			int(r_params[2]), # hp
		])
		
	game_message.emit([Message.Type.RESOURCES_STATE, parsed])

func _parse_configuration(msg: String) -> void:
	var params = msg.split(end_param,false)
	if params.size() != 10:
		printerr("Invalid configuration")
		return
		
	var parsed = []
	for i in range(9):
		if !params[i].is_valid_int():
			printerr("Invalid configuration param: %d = %s" % [i, params[i]])
			return
		parsed.append(int(params[i]))
	parsed.append(params[9])
	game_message.emit([Message.Type.CONFIGURATION, parsed])

func _parse_join_left(type: Message.Type, msg: String) -> void:
	game_message.emit([type,msg])

func _parse_dig(msg: String) -> void:
	game_message.emit([Message.Type.DIG,msg])

func _parse_moved(msg: String) -> void:
	var params = msg.split(end_param,false)
	if params.size() != 3:
		printerr("Invalid moved message")
		return
	if !params[1].is_valid_int() or !params[2].is_valid_int():
		printerr("Invalid move position: %s %s" % [params[1],params[2]])
		return
	
	game_message.emit([Message.Type.MOVE,[
		params[0],
		Vector2i(int(params[1]),int(params[2]))
	]])

func _parse_attack(msg: String) -> void:
	var params = msg.split(end_param,false)
	if params.size() != 2:
		printerr("Invalid attack message")
		return
	game_message.emit([Message.Type.ATTACK,[
		params[0],
		params[1]
	]])

func _parse_unit(msg: String) -> void:
	var params = msg.split(end_param,false)
	if params.size() != 4:
		printerr("Invalid new unit message")
		return
		
	if !params[2].is_valid_int() or !params[3].is_valid_int():
		printerr("Invalid new unit position: %s %s" % [params[2],params[3]])
		return
		
	game_message.emit([Message.Type.UNIT,[
		params[0],
		params[1],
		Vector2i(int(params[2]),int(params[3]))
	]])

func _parse_field_resource(msg: String) -> void:
	var params = msg.split(end_param,false)
	if params.size() != 3:
		printerr("Invalid new resource message")
		return
	if !params[0].is_valid_int() or !params[1].is_valid_int():
		printerr("Invalid new resource position: %s %s" % [params[0],params[1]])
		return
	if !params[2].is_valid_int():
		printerr("Invalid new resource hp: %s" % params[2])
		return
	game_message.emit([Message.Type.FIELD_RESOURCE,[
		Vector2i(int(params[0]),int(params[1])),
		params[2]
	]])
	
func _handle_msg(msg: String) -> void:
	var decoded: Array = Message.decode(msg)
	var type = decoded[0]
	if type == null:
		printerr("Invalid message")
		return
		
	match type:
		Message.Type.MOVE:
			_parse_moved(decoded[1])
		Message.Type.ATTACK:
			_parse_attack(decoded[1])
		Message.Type.DIG:
			_parse_dig(decoded[1])
		Message.Type.UNIT:
			_parse_unit(decoded[1])
		Message.Type.FIELD_RESOURCE:
			_parse_field_resource(decoded[1])
		Message.Type.CONFIGURATION:
			_parse_configuration(decoded[1])
		Message.Type.JOIN:
			_parse_join_left(type, decoded[1])
		Message.Type.LEFT:
			_parse_join_left(type, decoded[1])
		Message.Type.PLAYERS_STATE:
			_parse_players_state(decoded[1])
		Message.Type.RESOURCES_STATE:
			_parse_resources_state(decoded[1])
		_:
			game_message.emit([type])

func _on_partial_data(data: String) -> void:
	if !data.contains(end_msg):
		_client.data.disconnect(self._on_partial_data)
		while !data.contains(end_msg):
			data += await _client.data
		_client.data.connect(self._on_partial_data)
	
	var msg_extra = data.split(end_msg,false,1)
	if msg_extra.size() >= 1:
		_handle_msg(msg_extra[0])
	if msg_extra.size() >= 2:
		_client.data.emit(msg_extra[1])

func  _ready():
	_client.connected.connect(self._on_connected)
	_client.disconnected.connect(self._on_disconnected)
	_client.error.connect(self._on_error)
	_client.data.connect(self._on_partial_data)
	add_child(_client)

func init_connection():
	_client.connect_to_host(host, port)

func disconnect_from_host() -> void:
	_client.disconnect_from_host()

func send_msg(msg: Message.Type):
	_msg_queue.append(Message.encode(msg))

func send_msg_val(type: Message.Type, val: String):
	_msg_queue.append(Message.encode(type, val))
	
func _send_partial_msg(msg: PackedByteArray) -> int:
	var res = _client.send(msg)
	if res[0] != OK:
		return 0
	return res[1]

func _process(_delta):
	if !_msg_queue.is_empty():
		var msg: PackedByteArray = _msg_queue.pop_front()
		var sent = _send_partial_msg(msg)
		if sent < msg.size():
			_msg_queue.push_front(msg.slice(sent+1))
	
