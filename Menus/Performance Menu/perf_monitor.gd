extends CanvasLayer

@onready var fps_label = $MarginContainer/HBoxContainer/FPSCounter
@onready var gpu_label = $MarginContainer/HBoxContainer/GpuUsage
@onready var cpu_label = $MarginContainer/HBoxContainer/CpuUsage
@onready var frametime_label = $MarginContainer/HBoxContainer/FrameTime
@onready var ram_label = $MarginContainer/HBoxContainer/RAMUsage
@onready var vram_label = $MarginContainer/HBoxContainer/VRAMUsage

func _ready():
	self.hide()
	set_process(false)

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	var frame_time = 1000.0 / fps if fps > 0 else 0.0
	var ram = OS.get_static_memory_usage() / 1048576.0
	var vram = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var gpu = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var cpu_process = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var cpu_physics = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	
	fps_label.text = "FPS: " + str(int(fps))
	frametime_label.text = "Frame Time: " + str(int(frame_time))
	ram_label.text = "RAM: " + str(int(ram)) + " MB"
	vram_label.text = "VRAM: " + str(int(vram)) + " MB"
	gpu_label.text = "GPU Draw Calls: " + str(int(gpu))
	cpu_label.text = "CPU Process Time: " + str(cpu_process) + " / Physics Time: " + str(cpu_physics)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_monitor"):
		if self.is_processing():
			self.set_process(false)
		else:
			self.set_process(true)
		self.visible = !self.visible
