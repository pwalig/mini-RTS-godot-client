extends Node

signal game_message(Array)
signal connection_result(bool)
signal error

@export var host: String = "127.0.0.1" : set = _set_host
@export var port: int = 1234 : set = _set_port

const end_msg = CONFIG.end_msg

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

func _handle_msg(msg: String) -> void:
	var parsed: Array = Parser.parse(msg)
	if parsed:
		game_message.emit(parsed)

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

func send_msg_str(type: Message.Type, val: String):
	_msg_queue.append(Message.encode_str(type, val))

func send_msg_params(type: Message.Type, params: Array):
	_msg_queue.append(Message.encode_params(type, params))
	
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
