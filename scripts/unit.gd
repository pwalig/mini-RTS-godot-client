class_name Unit
extends AnimatedSprite2D

@export var owner_nick: String = "" : set = set_owner_nick
func set_owner_nick(nick: String) -> void:
	owner_nick = nick
	$OwnerNickLabel.text = nick
	var hue = (abs(hash(nick)) % 256) / 256.0
	self_modulate = Color.from_hsv(hue, 1.0, 1.0)

@export var cell_position: Vector2i = Vector2i(-1,-1) : set = set_cell_position
func set_cell_position(pos: Vector2i) -> void:
	if cell_position == pos:
		return
		
	flip_h = pos.x < cell_position.x
	if cell_position == Vector2i(-1,-1):
		cell_position = pos
		position = Vector2(pos) * CONFIG.tilesize
		return
	cell_position = pos
	call_deferred("_move", Vector2(pos) * CONFIG.tilesize)

func _move(pos: Vector2) -> void:
	play("run")
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position", pos, 0.2)
	pos_tween.tween_callback(play.bind("idle"))

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

func _on_zoom_change(zoom: float) -> void:
	if zoom < CONFIG.LOD_tresh:
		$OwnerNickLabel.visible = false
		$HPBar.visible = false
	else:
		$OwnerNickLabel.visible = true
		$HPBar.visible = true

func _ready():
	$HPBar.max_value = CONFIG.max_unit_health
	var cam: GameCamera = get_tree().get_first_node_in_group("camera")
	cam.zoom_change.connect(self._on_zoom_change)
