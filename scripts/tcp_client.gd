class_name TCPClient extends Node

signal connected
signal disconnected
signal data
signal error

var _tcp_stream: StreamPeerTCP = StreamPeerTCP.new()
var _status: int
	
func connect_to_host(host: String, port: int) -> void:
	print("Connecting to %s:%d" % [host, port])
	_status = _tcp_stream.STATUS_NONE
	var err = _tcp_stream.connect_to_host(host, port)
	if err!= OK:
		printerr("Connection error")
		error.emit(err)

func send(data_to_send: PackedByteArray) -> Array:
	if _status != _tcp_stream.STATUS_CONNECTED:
		return [1,0]
	return _tcp_stream.put_partial_data(data_to_send)

func _status_updated(new_status: int) -> void:
	_status = new_status
	match _status:
		_tcp_stream.STATUS_NONE:
			print("Status Disconnected")
			disconnected.emit()
		_tcp_stream.STATUS_CONNECTING:
			print("Status Connecting")
		_tcp_stream.STATUS_CONNECTED:
			print("Status Connected")
			connected.emit()
		_tcp_stream.STATUS_ERROR:
			printerr("Status error")
			error.emit(1)

func _try_recieve_data() -> void:
	if _status != _tcp_stream.STATUS_CONNECTED:
		return
	var avaliable: int = _tcp_stream.get_available_bytes()
	if avaliable <= 0:
		return
	var partial_data: Array = _tcp_stream.get_partial_data(avaliable)
	if partial_data[0] != OK:
		printerr("get_partial_data error")
		return
	data.emit(partial_data[1])

func _ready():
	_status = _tcp_stream.get_status()

func _process(_delta):
	_tcp_stream.poll()
	var new_status = _tcp_stream.get_status()
	if(_status != new_status):
		_status_updated(new_status)
	_try_recieve_data()
	
