extends Line2D

func _ready():
	%Camera.zoom_change.connect(self._on_zoom_change)

func _on_zoom_change(zoom: float):
	width = 2 / zoom

func draw_select_rect(r: Rect2i) -> void:
	var rect = r.abs()
	clear_points()
	add_point(Vector2(rect.position) * CONFIG.tilesize)
	add_point(Vector2(rect.end.x+1, rect.position.y) * CONFIG.tilesize)
	add_point((Vector2(rect.end)+Vector2.ONE) * CONFIG.tilesize)
	add_point(Vector2(rect.position.x, rect.end.y+1) * CONFIG.tilesize)
