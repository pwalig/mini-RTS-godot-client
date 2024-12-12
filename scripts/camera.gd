extends Camera2D

const zoom_speed = 0.1
const max_zoom = Vector2(5,5)
const min_zoom = Vector2(0.2,0.2)

var screen_drag : bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action("secondary_click"):
			screen_drag = event.pressed
		elif event.is_action_pressed("zoom_in"):
			zoom = clamp(zoom + Vector2.ONE * zoom_speed, min_zoom, max_zoom)
		elif event.is_action_pressed("zoom_out"):
			zoom = clamp(zoom - Vector2.ONE * zoom_speed, min_zoom, max_zoom)
			
	if screen_drag and event is InputEventMouseMotion:
		position -= event.relative * (Vector2.ONE / zoom)
