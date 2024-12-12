extends Node

enum GameState{
	MENU_INIT,
	WAIT_FOR_CONNECTION,
	MENU_CONNECTED,
	QUEUE,
	PLAYING
}

const _menu_states = [GameState.MENU_INIT, GameState.WAIT_FOR_CONNECTION, GameState.MENU_CONNECTED]

var _game_state: GameState = GameState.MENU_INIT : set = _set_game_state

func _set_game_state(new_state: GameState) -> void:
	if _game_state == new_state:
		return
	match new_state:
		GameState.PLAYING:
			_switch_to_game()
		GameState.MENU_INIT:
			_switch_to_menu(true)
		GameState.MENU_CONNECTED:
			_switch_to_menu(false)
	_game_state = new_state
	print("Game state: ",GameState.keys()[_game_state])

var main_menu_s = preload("res://scenes/main_menu.tscn")
var game_s = preload("res://scenes/game.tscn")

var _player_nick: String = ""

func _ready():
	$MainMenu.join_game.connect(self._on_join_game)
	TcpConnection.game_message.connect(self._on_game_message)
	TcpConnection.error.connect(self._on_connection_error)

func _switch_to_game() -> void:
	if _game_state == GameState.PLAYING:
		return
	var menu = get_node("MainMenu")
	var game = game_s.instantiate()
	add_child(game)
	menu.queue_free()

func _switch_to_menu(was_disconnected: bool) -> void:
	if _game_state in _menu_states:
		return
	var game = get_node("Game")
	var menu = main_menu_s.instantiate()
	menu.need_new_connection = was_disconnected
	menu.set_nick(_player_nick)
	menu.join_game.connect(self._on_join_game)
	add_child(menu)
	game.queue_free()

func _on_join_game() -> void:
	if _game_state == GameState.MENU_INIT:
		TcpConnection.init_connection()
		_game_state = GameState.WAIT_FOR_CONNECTION
		var connected = await TcpConnection.connection_result
		if not connected:
			printerr("Not connected")
			_game_state = GameState.MENU_INIT
			return
			
	var menu = get_node_or_null("MainMenu")
	if menu == null:
		printerr("Tried to join from outside menu")
		return
		
	TcpConnection.send_msg_val(Message.Type.NAME, menu.player_nick())
	var res = await TcpConnection.game_message
	if res[0] != Message.Type.YES:
		print("Nick rejected!")
		menu.inform_user("Nick rejected!")
		return
	_player_nick = menu.player_nick()
	print("Nick accepted: ", _player_nick)
		
	TcpConnection.send_msg(Message.Type.JOIN)
	res = await TcpConnection.game_message
	if res[0] == Message.Type.ACCEPTED:
		_game_state = GameState.PLAYING
	elif res[0] == Message.Type.QUEUED:
		_game_state = GameState.QUEUE
	else:
		printerr("Join Game -> Unexpected response from server")
		
func _on_connection_error() -> void:
	_game_state = GameState.MENU_INIT
	var menu = get_node_or_null("MainMenu")
	if menu != null:
		menu.inform_user("Disconnected from server")

func _on_game_message(msg: Array) -> void:
	var type: Message.Type = msg[0]
	print(Message.Type.keys()[type])
	
	match type:
		Message.Type.INVALID:
			printerr("Client supposed to have sent invalid message")
