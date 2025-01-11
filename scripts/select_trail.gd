extends Sprite2D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(queue_free)
