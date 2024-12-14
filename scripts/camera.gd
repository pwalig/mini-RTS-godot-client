extends Camera2D

const zoom_speed = 0.1
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
			new_zoom = clamp(zoom + Vector2.ONE * zoom_speed, min_zoom, max_zoom)
		elif event.is_action_pressed("zoom_out"):
			new_zoom = clamp(zoom - Vector2.ONE * zoom_speed, min_zoom, max_zoom) 
		
		var delta_zoom = new_zoom - zoom
		var half_size = get_viewport_rect().size * 0.5
		#print((event.position - half_size))
		if delta_zoom.length() > 0:
			var off = (event.position - half_size) * (delta_zoom / zoom)
			zoom = new_zoom
			position += off
			
	if screen_drag and event is InputEventMouseMotion:
		position -= event.relative * (Vector2.ONE / zoom)
