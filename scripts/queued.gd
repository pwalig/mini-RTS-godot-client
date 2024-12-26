extends Control

func _ready():
	TcpConnection.game_message.connect(self._on_game_message)
	
func _on_game_message(_msg: Array) -> void:
	# currently no queued specific actions
	pass
