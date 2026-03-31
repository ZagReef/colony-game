extends Camera2D

var zoom_speed := 0.1
var zoom_min := 0.1
var zoom_max := 3.0
var zoom_factor = 1.1

var dragging := false
var last_mouse_pos := Vector2.ZERO

var is_following: bool = false
var following_pawn: PawnPrototype = null
signal cam_went

func _ready():
	PawnManager.pawn_focus_requested.connect(focus_target)
	PawnManager.pawn_focus_cancelled.connect(unfocus_cam)
	set_process(false)

func _process(_delta: float) -> void:
	if is_following and following_pawn != null:
		global_position = following_pawn.global_position

func _unhandled_input(event):
	if event is InputEventMouseButton:
		"""if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.0 + zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= 1.0 - zoom_speed"""
	
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_to_mouse(zoom_factor, get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_to_mouse(1.0 / zoom_factor, get_global_mouse_position())
	
		# zoom limitleri uygula
		zoom.x = clamp(zoom.x, zoom_min, zoom_max)
		zoom.y = clamp(zoom.y, zoom_min, zoom_max)
	
		# Mouse orta tuşla sürükleme başlat
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			last_mouse_pos = get_viewport().get_mouse_position()
	
	elif event is InputEventMouseMotion and dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta = mouse_pos - last_mouse_pos
		position -= delta / zoom  # zoom oranına göre hareket
		last_mouse_pos = mouse_pos

func zoom_to_mouse(factor: float, mouse_pos: Vector2):
	var old_zoom = zoom
	var new_zoom = old_zoom * factor
	
	new_zoom.x = clamp(new_zoom.x, zoom_min, zoom_max)
	new_zoom.y = clamp(new_zoom.y, zoom_min, zoom_max)
	
	if old_zoom == new_zoom:
		return
	
	var offset_ = mouse_pos - global_position
	
	var new_offset = offset_ * (old_zoom / new_zoom)
	
	zoom = new_zoom
	
	global_position = mouse_pos - new_offset

func focus_target(target_pawn: CharacterBody2D):
	#global_position = target_pawn.global_position
	set_process(false)
	
	var tween = create_tween()
	tween.set_speed_scale(1.0 / Engine.time_scale)
	
	tween.tween_property(
		self,
		"global_position",
		target_pawn.global_position,
		0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	is_following = true
	following_pawn = target_pawn
	
	await get_tree().create_timer(0.5).timeout
	
	set_process(true)

func unfocus_cam():
	is_following = false
	following_pawn = null
	set_process(false)
