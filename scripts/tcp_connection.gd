extends Node

signal game_message(Array)
signal connection_result(bool)
signal error

@export var host: String = "127.0.0.1" : set = _set_host
@export var port: int = 1234 : set = _set_port

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

func _complete_game_joined_message(msg_part: String) -> void:
	_client.data.disconnect(self._on_partial_data)
	
	while msg_part.find(";") == -1:
		var data: PackedByteArray = await _client.data
		msg_part += data.get_string_from_utf8()
	
	var data_extra: PackedStringArray = msg_part.split(";",false,1)
	var game_joined_msg: PackedStringArray = data_extra[0].split(" ", false)
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
	
	_client.data.connect(self._on_partial_data)
	
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
	
