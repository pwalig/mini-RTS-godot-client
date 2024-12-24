extends Node2D

func init_game(player_nick: String, params: Array) -> void:
	print("game init")
	$Map.player_nick = player_nick
	$Map.setup_ground(params[0], params[1])

func _ready():
	TcpConnection.game_message.connect(self._on_game_message)
	
	#tmp
	init_game("john", [10,10])
	
	$Map.spawn_unit("john", "0", Vector2i(1,1))
	$Map.spawn_unit("john", "1", Vector2i(5,4))
	$Map.spawn_unit("adam", "2", Vector2i(2,2))
	$Map.spawn_unit("george", "3", Vector2i(2,4))
	
func _on_game_message(msg: Array) -> void:
	match msg[0]:
		Message.Type.CONFIGURATION:
			_apply_config(msg[1])
		Message.Type.PLAYERS_STATE:
			$Map.update_players(msg[1])
		Message.Type.RESOURCES_STATE:
			$Map.update_resources(msg[1])

var moves = [] # tmp
func _new_game_tick() -> void:
	# tmp
	for move in moves:
		var action = move[1]
		if action[0] == PlayerUnit.Action.MOVE:
			$Map.try_move_unit(move[0], action[1])
	moves.clear()
	
	get_tree().call_group("player_units","request_next_action")

func _on_unit_request_action(id: String, action: Array) -> void:
	print(id,": ",PlayerUnit.Action.keys()[action[0]]," ", action[1])
	moves.append([id, action])

func _apply_config(config: Array) -> void:
	pass
