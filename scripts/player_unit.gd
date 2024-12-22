class_name PlayerUnit
extends Unit

@export var selected: bool = false : set = _set_selected
func _set_selected(s: bool) -> void:
	selected = s
	material.set("shader_parameter/selected",true)

@export var outline_width: float = 0.02

func _on_zoom_change(zoom: float):
	super(zoom)
	material.set("shader_parameter/outline_width",outline_width/zoom)
#
#func _ready():
	#super()
