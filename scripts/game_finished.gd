class_name GameFinished
extends Control

var has_won: bool = false : set = _set_has_won
func _set_has_won(won: bool) -> void:
	has_won = won
	if won:
		%Msg.text = "YOU WIN"
	else:
		%Msg.text = "YOU LOST"

enum LoseReason{
	NO_UNITS,
	OTHER_WON
}

func set_reason(reason: LoseReason, nick = null):
	match reason:
		LoseReason.NO_UNITS:
			%Reason.text = "You lost all your units!"
		LoseReason.OTHER_WON:
			%Reason.text = "%s has won!" % nick
