extends Node

@export var host: String = "localhost"
@export var port: int = 2137

var _client = TCPClient.new()

func _on_connected() -> void:
	pass

func _on_disconnected() -> void:
	pass

func _on_error(err: int) -> void:
	pass

func _on_partial_data(data: PackedByteArray) -> void:
	print("Client data: ", data.get_string_from_utf8())

func  _ready():
	_client.connected.connect(self._on_connected)
	_client.disconnected.connect(self._on_disconnected)
	_client.error.connect(self._on_error)
	_client.data.connect(self._on_partial_data)
	add_child(_client)
	
	_client.connect_to_host(host, port)
