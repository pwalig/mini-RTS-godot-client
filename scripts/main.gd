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

func _on_connection_error() -> void:
	pass

func _on_game_message(msg: Array) -> void:
	print(msg)
