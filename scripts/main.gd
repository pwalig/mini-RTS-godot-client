extends Node

enum GameState{
	MENU_INIT,
	MENU_CONNECTED,
	QUEUE,
	PLAYING
}

var _game_state: GameState = GameState.MENU_INIT : set = _set_game_state

func _set_game_state(new_state: GameState) -> void:
	_game_state = new_state

var main_menu_s = preload("res://scenes/main_menu.tscn")

func _ready():
	$MainMenu.join_game.connect(self._on_join_game)
	TcpConnection.game_message.connect(self._on_game_message)
	TcpConnection.error.connect(self._on_connection_error)

func _on_join_game() -> void:
	if _game_state == GameState.MENU_INIT:
		TcpConnection.init_connection()
		var connected = await TcpConnection.connection_result
		if not connected:
			printerr("Not connected")
			return
		var menu = get_node_or_null("MainMenu")
		if menu == null:
			printerr("Tried to join from outside menu")
			return
		TcpConnection.send_msg_val(Message.Type.NAME, menu.player_nick())
		TcpConnection.send_msg(Message.Type.JOIN)
		
func _on_connection_error() -> void:
	pass

func _on_game_message(msg: Array) -> void:
	var type: Message.Type = msg[0]
	print(Message.Type.keys()[type])
