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
		GameState.QUEUE:
			_switch_to_queue()
		GameState.MENU_INIT:
			_switch_to_menu(true)
		GameState.MENU_CONNECTED:
			_switch_to_menu(false)
	_game_state = new_state
	print("Game state: ",GameState.keys()[_game_state])

var main_menu_s = preload("res://scenes/main_menu.tscn")
var game_s = preload("res://scenes/game.tscn")
var queue_s = preload("res://scenes/queued.tscn")

var _player_nick: String = ""

func _ready():
	$MainMenu.join_game.connect(self._on_join_game)
	TcpConnection.error.connect(self._on_connection_error)
	TcpConnection.game_message.connect(self._on_game_message)

func _switch_to_game() -> void:
	if _game_state == GameState.PLAYING:
		return
	for child in get_children():
		child.queue_free()
	var game = game_s.instantiate()
	add_child(game)
	game.init_game(_player_nick)

func _switch_to_menu(was_disconnected: bool) -> void:
	if _game_state in _menu_states:
		return
	for child in get_children():
		child.queue_free()
	var menu = main_menu_s.instantiate()
	menu.need_new_connection = was_disconnected
	menu.set_nick(_player_nick)
	menu.join_game.connect(self._on_join_game)
	add_child(menu)

func _switch_to_queue() -> void:
	if _game_state == GameState.QUEUE:
		return
	for child in get_children():
		child.queue_free()
	var queued = queue_s.instantiate()
	add_child(queued)

func _on_join_game() -> void:
	var menu = get_node_or_null("MainMenu")
	if menu == null:
		printerr("Tried to join from outside menu")
		return
		
	if _game_state == GameState.MENU_INIT and menu.need_new_connection:
		TcpConnection.init_connection()
		_game_state = GameState.WAIT_FOR_CONNECTION
		var connected = await TcpConnection.connection_result
		if not connected:
			printerr("Not connected")
			_game_state = GameState.MENU_INIT
			return
	
	var config = await TcpConnection.game_message
	# TODO validate player nick using config here
	
	TcpConnection.send_msg_str(Message.Type.NAME, menu.player_nick())
	var res = await TcpConnection.game_message
	
	if res[0] != Message.Type.YES:
		print("Nick rejected!")
		menu.inform_user("Nick rejected!")
		menu.need_new_connection = false
		return
		
	_player_nick = menu.player_nick()
	print("Nick accepted: ", _player_nick)
	menu.inform_user("Nick accepted, waiting for join")
		
	TcpConnection.send_msg(Message.Type.JOIN)	
		
func _on_connection_error() -> void:
	_game_state = GameState.MENU_INIT
	var menu = get_node_or_null("MainMenu")
	if menu != null:
		menu.inform_user("Disconnected from server")
		menu.need_new_connection = true

func _print_message(msg: Array) -> void:
	if msg.size() == 1:
		print(Message.Type.keys()[msg[0]])
	else:
		print(Message.Type.keys()[msg[0]], msg[1])

func _on_game_message(msg: Array) -> void:
	_print_message(msg)
	
	var type: Message.Type = msg[0]
	match type:
		Message.Type.PLAYERS_STATE:
			if _game_state != GameState.PLAYING:
				_game_state = GameState.PLAYING
				get_node("Game")._on_game_message(msg)
		Message.Type.CONFIGURATION:
			CONFIG.apply(msg[1])
		Message.Type.QUEUED:
			_game_state = GameState.QUEUE

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("disconnecting")
		TcpConnection.disconnect_from_host()
		_game_state = GameState.MENU_INIT
		get_node("MainMenu").need_new_connection = true
