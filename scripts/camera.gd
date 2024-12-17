extends Camera2D

const zoom_speed = Vector2(0.2,0.2)
const max_zoom = Vector2(1,1)
const min_zoom = Vector2(0.02,0.02)

var screen_drag : bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action("secondary_click"):
			screen_drag = event.pressed
			return
		var new_zoom = zoom
		if event.is_action_pressed("zoom_in"):
			new_zoom = clamp(zoom * (Vector2.ONE + zoom_speed),min_zoom,max_zoom)
		elif event.is_action_pressed("zoom_out"):
			new_zoom = clamp(zoom * (Vector2.ONE - zoom_speed),min_zoom,max_zoom)
		
		var mouse_pos = get_global_mouse_position()
		zoom = new_zoom
		position += mouse_pos - get_global_mouse_position()
		force_update_transform()
			
	if screen_drag and event is InputEventMouseMotion:
		position -= event.relative * (Vector2.ONE / zoom)
