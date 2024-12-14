extends Node

signal game_message(Array)
signal connection_result(bool)
signal error

@export var host: String = "127.0.0.1" : set = _set_host
@export var port: int = 1234 : set = _set_port

const end_line = "\n"
const end_prop = " "

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

func _on_partial_data(data: PackedByteArray) -> void:
	var decoded: Array = Message.decode(data)
	var type = decoded[0]
	if type == null:
		printerr("Invalid message")
		return
		
	match type:
		Message.Type.GAME_JOINED:
			await _complete_game_joined_message(decoded[1])
		Message.Type.BOARD_STATE:
			await _complete_board_state_message(decoded[1])
		_:
			game_message.emit([type])
			if !decoded[1].is_empty():
				_client.data.emit(decoded[1].to_utf8_buffer())

func _complete_game_joined_message(msg_part: String) -> void:
	_client.data.disconnect(self._on_partial_data)
	
	while msg_part.find(end_line) == -1:
		var data: PackedByteArray = await _client.data
		msg_part += data.get_string_from_utf8()
	
	var data_extra: PackedStringArray = msg_part.split(end_line,false,1)
	var game_joined_msg: PackedStringArray = data_extra[0].split(end_prop, false)
	if game_joined_msg.size() != 3:
		printerr("Incorrect game joined message!")
	else:
		if !game_joined_msg[0].is_valid_int():
			printerr("Incorrect boardX")
		elif !game_joined_msg[1].is_valid_int():
			printerr("Incorrect boardY")
		elif !game_joined_msg[2].is_valid_int():
			printerr("Incorrect unitsToWin")
		else:
			game_message.emit([Message.Type.GAME_JOINED, [
				int(game_joined_msg[0]), # boardX
				int(game_joined_msg[1]), # boardY
				int(game_joined_msg[2]), # unitsToWin
			]])
	
	_client.data.connect(self._on_partial_data)
	if data_extra.size() > 1:
		_client.data.emit(data_extra[1].to_utf8_buffer())

func _complete_board_state_message(msg_part: String) -> void:
	_client.data.disconnect(self._on_partial_data)
	
	var board_state = {}
	
	while msg_part.find(end_line) == -1:
		var data: PackedByteArray = await _client.data
		msg_part += data.get_string_from_utf8()
	
	var player_c_extra = msg_part.split(end_line,false,1)
	if !player_c_extra[0].is_valid_int():
		printerr("Incorrect amount of players")
		_client.data.connect(self._on_partial_data)
		return
	
	var player_c = int(player_c_extra[0])
	
	if player_c_extra.size() > 1:
		msg_part = player_c_extra[1]
	else:
		msg_part = ""
		
	board_state["players"] = {}
	for p in range(player_c):
		while msg_part.find(end_line) == -1:
			var data: PackedByteArray = await _client.data
			msg_part += data.get_string_from_utf8()
			
		var player_extra = msg_part.split(end_line,false,1)
		var player = player_extra[0].split(end_prop,false)
		if player.size() != 2:
			printerr("Incorrect player data")
			_client.data.connect(self._on_partial_data)
			return
		if !player[1].is_valid_int():
			printerr("Incorrect amount of player units")
			_client.data.connect(self._on_partial_data)
			return
		
		var player_nick = player[0]
		var player_unit_c = int(player[1])
		board_state["players"][player_nick] = {}
		
		if player_extra.size() > 1:
			msg_part = player_extra[1]
		else:
			msg_part = ""
		
		var units = []
		for u in range(player_unit_c):
			while msg_part.find(end_line) == -1:
				var data: PackedByteArray = await _client.data
				msg_part += data.get_string_from_utf8()
			var unit_extra = msg_part.split(end_line,false,1)
			var unit = unit_extra[0].split(end_prop,false)
			if unit.size() != 3:
				printerr("Incorrect unit data")
				_client.data.connect(self._on_partial_data)
				return
			var unit_arr = []
			for v in unit:
				if !v.is_valid_int():
					printerr("Incorrect unit position or hp")
					_client.data.connect(self._on_partial_data)
					return
				unit_arr.append(int(v))
			units.append(unit_arr)
			
			if unit_extra.size() > 1:
				msg_part = unit_extra[1]
			else:
				msg_part = ""
				
		board_state["players"][player_nick]["units"] = units
		
	while msg_part.is_empty():
			var data: PackedByteArray = await _client.data
			msg_part += data.get_string_from_utf8()
	
	if msg_part[0] != "r":
		printerr("No resource data")
		_client.data.connect(self._on_partial_data)
		return
	
	while msg_part.find(end_line) == -1:
		var data: PackedByteArray = await _client.data
		msg_part += data.get_string_from_utf8()
	
	var resource_data_extra = msg_part.split(end_line,false,1)
	var resource_data = resource_data_extra[0].substr(1)
	if !resource_data.is_valid_int():
		printerr("Incorrect resources data")
		_client.data.connect(self._on_partial_data)
		return
	var resource_c = int(resource_data)
	
	if resource_data_extra.size() > 1:
		msg_part = resource_data_extra[1]
	else:
		msg_part = ""
	
	var resources = []
	for r in range(resource_c):
		while msg_part.find(end_line) == -1:
			var data: PackedByteArray = await _client.data
			msg_part += data.get_string_from_utf8()
		var resource_extra = msg_part.split(end_line,false,1)
		var resource = resource_extra[0].split(end_prop,false)
		if resource.size() != 3:
			printerr("Incorrect resource data")
			_client.data.connect(self._on_partial_data)
			return
		var resource_arr = []
		for v in resource:
			if !v.is_valid_int():
				printerr("Incorrect resource position or hp")
				_client.data.connect(self._on_partial_data)
				return
			resource_arr.append(int(v))
		resources.append(resource_arr)
		if resource_extra.size() > 1:
			msg_part = resource_extra[1]
		else:
			msg_part = ""
			
	board_state["resources"] = resources
	game_message.emit([Message.Type.BOARD_STATE, board_state])
	_client.data.connect(self._on_partial_data)
	if !msg_part.is_empty():
		_client.data.emit(msg_part.to_utf8_buffer())
	
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
	
