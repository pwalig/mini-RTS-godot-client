extends Node2D

func init_game(player_nick: String) -> void:
	print("game init")
	$Map.player_nick = player_nick
	$Map.setup_ground()

func _ready():
	TcpConnection.game_message.connect(self._on_game_message)

func _on_game_message(msg: Array) -> void:
	match msg[0]:
		Message.Type.TICK:
			_new_game_tick()
		Message.Type.MOVE:
			$Map.handle_move(msg[1])
		Message.Type.DIG:
			$Map.handle_dig(msg[1])
		Message.Type.ATTACK:
			$Map.handle_attack(msg[1])
		Message.Type.UNIT:
			$Map.spawn_unit_arr(msg[1])
		Message.Type.FIELD_RESOURCE:
			$Map.spawn_resource(msg[1])
		Message.Type.PLAYERS_STATE:
			$Map.update_players(msg[1])
		Message.Type.RESOURCES_STATE:
			$Map.update_resources(msg[1])
		Message.Type.LEFT:
			$Map.kill_player_units(msg[1])

func _new_game_tick() -> void:
	get_tree().call_group("player_units","request_next_action")

func _on_unit_request_action(_id: String, action: Array) -> void:
	#print(id,": ",PlayerUnit.Action.keys()[action[0]]," ", action[1])
	match action[0]:
		PlayerUnit.Action.MOVE:
			TcpConnection.send_msg_params(Message.Type.MOVE, [
				action[1].x, action[1].y,
				action[2].x, action[2].y
				])
		PlayerUnit.Action.MINE:
			TcpConnection.send_msg_params(Message.Type.DIG, [
				action[1].x, action[1].y
				])
		PlayerUnit.Action.ATTACK:
			TcpConnection.send_msg_params(Message.Type.ATTACK, [
				action[1].x, action[1].y,
				action[2].x, action[2].y
				])
