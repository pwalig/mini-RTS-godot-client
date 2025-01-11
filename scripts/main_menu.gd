extends Control

signal join_game

var need_new_connection: bool = true : set = _set_need_new_connection
func _set_need_new_connection(val: bool) -> void:
	need_new_connection = val
	%ConnectionData.visible = val

func _ready():
	%HostEdit.text = TcpConnection.host
	%PortEdit.text = str(TcpConnection.port)

func _on_join_game_button_pressed():
	if need_new_connection:
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

func is_nick_valid(allowed: String = CONFIG.allowedNameCharacters) -> bool:
	var ret: bool = true
	var reg = RegEx.new()
	reg.compile("^[%s]{1,20}$" % allowed)
	# TODO get min and max length from config when implemented
	return reg.search(%NickEdit.text) != null

func set_nick(nick: String) -> void:
	%NickEdit.text = nick

func inform_user(text: String) -> void:
	%InformLabel.text = text
	var tween = get_tree().create_tween()
	tween.tween_property(%InformLabel, "self_modulate", Color.WHITE, 0.3)
	tween.tween_property(%InformLabel, "self_modulate", Color(1,1,1,0), 5)
