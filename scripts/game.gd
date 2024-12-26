extends Node2D

func init_game(player_nick: String) -> void:
	print("game init")
	$Map.player_nick = player_nick
	$Map.setup_ground()

func _ready():
	TcpConnection.game_message.connect(self._on_game_message)
	
	#tmp
	#init_game("john")
	#
	#$Map.spawn_unit("john", "0", Vector2i(1,1))
	#$Map.spawn_unit("john", "1", Vector2i(5,4))
	#$Map.spawn_unit("adam", "2", Vector2i(2,2))
	#$Map.spawn_unit("george", "3", Vector2i(2,4))
	
func _on_game_message(msg: Array) -> void:
	match msg[0]:
		Message.Type.TICK:
			_new_game_tick()
		Message.Type.MOVE:
			$Map.queue_move_unit(msg[1])
		Message.Type.DIG:
			$Map.queue_mine_resource(msg[1])
		Message.Type.ATTACK:
			$Map.queue_attack_unit(msg[1])
		Message.Type.UNIT:
			#var params: Array = msg[1]
			#$Map.spawn_unit(params[0], params[1], params[2])
			$Map.spawn_unit_arr(msg[1])
		Message.Type.FIELD_RESOURCE:
			$Map.spawn_resource(msg[1])
		Message.Type.PLAYERS_STATE:
			$Map.update_players(msg[1])
		Message.Type.RESOURCES_STATE:
			$Map.update_resources(msg[1])

#var moves = [] # tmp
func _new_game_tick() -> void:
	## tmp
	#for move in moves:
		#var action = move[1]
		#if action[0] == PlayerUnit.Action.MOVE:
			#$Map.try_move_unit(move[0], action[1])
	#moves.clear()
	$Map.commit_moves()
	get_tree().call_group("player_units","request_next_action")

func _on_unit_request_action(id: String, action: Array) -> void:
	#print(id,": ",PlayerUnit.Action.keys()[action[0]]," ", action[1])
	#moves.append([id, action])
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
