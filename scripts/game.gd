extends Node2D

func init_game(player_nick: String, params: Array) -> void:
	print("game init")
	$Map.player_nick = player_nick
	$Map.setup_ground(params[0], params[1])

func _ready():
	TcpConnection.game_message.connect(self._on_game_message)
	
func _on_game_message(msg: Array) -> void:
	match msg[0]:
		Message.Type.PLAYERS_STATE:
			$Map.update_players(msg[1])
		Message.Type.RESOURCES_STATE:
			$Map.update_resources(msg[1])
