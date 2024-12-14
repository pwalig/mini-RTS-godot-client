extends Node2D

func init_game(params: Array) -> void:
	print("game init")
	$Map.setup_ground(params[0], params[1])

func _ready():
	TcpConnection.game_message.connect(self._on_game_message)
	
func _on_game_message(msg: Array) -> void:
	pass
