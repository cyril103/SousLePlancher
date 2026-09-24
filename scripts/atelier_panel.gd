extends PanelContainer
## Material-backed frame. Atlas regions remain intact; only the GPU samples them.
const MATERIALS = preload("res://assets/ui/atelier/materials.png")
var paper := false
var linen := false

func _ready() -> void:
	var margins := StyleBoxEmpty.new()
	margins.set_content_margin_all(18)
	add_theme_stylebox_override("panel", margins)
	resized.connect(queue_redraw)

func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color("21170ff5")
	shadow.set_corner_radius_all(9)
	shadow.shadow_color = Color(0, 0, 0, 0.48)
	shadow.shadow_size = 6
	shadow.shadow_offset = Vector2(0, 3)
	shadow.draw(get_canvas_item(), full)
	var half := MATERIALS.get_size() / 2.0
	if linen:
		draw_texture_rect_region(MATERIALS, full.grow(-2), Rect2(Vector2(0, half.y), half))
	var inset := 7.0 if linen else 2.0
	var surface := full.grow(-inset)
	var source := Vector2(half.x, 0) if paper else Vector2.ZERO
	draw_texture_rect_region(MATERIALS, surface, Rect2(source + Vector2(4, 4), half - Vector2(8, 8)))
	var edge := StyleBoxFlat.new()
	edge.bg_color = Color.TRANSPARENT
	edge.border_color = Color("8b693c") if not paper else Color("b7a079")
	edge.set_border_width_all(2)
	edge.set_corner_radius_all(6)
	edge.draw(get_canvas_item(), surface)
	draw_rect(surface.grow(-4), Color("d2aa624d"), false, 1)
	for p in [surface.position + Vector2(9, 9), Vector2(surface.end.x - 9, surface.position.y + 9), surface.end - Vector2(9, 9), Vector2(surface.position.x + 9, surface.end.y - 9)]:
		draw_circle(p + Vector2(0, 1), 4.0, Color("140e09"))
		draw_circle(p, 3.3, Color("b68e43"))
		draw_arc(p, 2.5, PI, TAU, 10, Color("f2d58e"), 1, true)
		draw_line(p - Vector2(1.5, -1.5), p + Vector2(1.5, -1.5), Color("4f3719"), 1, true)
