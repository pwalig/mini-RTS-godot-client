extends Control

signal join_game

var need_new_connection: bool = true : set = _set_need_new_connection
func _set_need_new_connection(val: bool) -> void:
	need_new_connection = val
	%ConnectionData.visible = val

func _on_join_game_button_pressed():
	if !%HostEdit.text.is_valid_ip_address():
		return
	if !%PortEdit.text.is_valid_int():
		return
	var port_int = int(%PortEdit.text)
	if port_int < 0 or port_int > 65535:
		return
	TcpConnection.host = %HostEdit.text
	TcpConnection.port = int(%PortEdit.text)
	join_game.emit()

func player_nick() -> String:
	return %NickEdit.text
