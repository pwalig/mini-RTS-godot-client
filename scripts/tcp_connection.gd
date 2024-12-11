extends Node

signal game_message(Array)
signal connection_result(bool)
signal error

@export var host: String = "localhost" : set = _set_host
@export var port: int = 2137 : set = _set_port

var msg_queue: Array = []

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
	pass

func _on_error(err: int) -> void:
	connection_result.emit(false)

func _on_partial_data(data: PackedByteArray) -> void:
	print("Client data: ", data.get_string_from_utf8())

func  _ready():
	_client.connected.connect(self._on_connected)
	_client.disconnected.connect(self._on_disconnected)
	_client.error.connect(self._on_error)
	_client.data.connect(self._on_partial_data)
	add_child(_client)

func init_connection():
	_client.connect_to_host(host, port)

func send_msg(msg: Array):
	if msg.size() > 1:
		msg_queue.append(Message.encode(msg[0], msg[1]))
	else:
		msg_queue.append(Message.encode(msg[0]))

func _process(delta):
	if msg_queue.is_empty():
		return
