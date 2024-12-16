class_name Unit
extends AnimatedSprite2D

@export var owner_nick: String = "" : set = set_owner_nick
func set_owner_nick(nick: String) -> void:
	owner_nick = nick
	$OwnerNickLabel.text = nick
	var hue = (abs(hash(nick)) % 256) / 256.0
	self_modulate = Color.from_hsv(hue, 1.0, 1.0)

@export var cell_position: Vector2 = Vector2(0,0) : set = set_cell_position # might not be Vector2i while moving
func set_cell_position(pos: Vector2) -> void:
	cell_position = pos
	position = pos * 256.0

@export var hp: int = 10 : set = set_hp
func set_hp(new_hp: int) -> void:
	hp = new_hp
	$HPBar.value = new_hp

var keep_alive: bool = false
var dying: bool = false
func die_if_should() -> void:
	if !keep_alive and !dying:
		dying = true
		_die()
	else:
		keep_alive = false

func _die() -> void:
	call_deferred("queue_free")

func _ready():
	$HPBar.max_value = CONFIG.max_unit_health
