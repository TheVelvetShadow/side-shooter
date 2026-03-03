## Fullscreen vignette overlay.
## Add as a CanvasLayer child of any scene (main game, main menu, etc.)
## Tweak `strength` and `opacity` in the Inspector or via set_params().
extends CanvasLayer

@export var strength: float = 1.2
@export var opacity: float  = 0.85

func _ready() -> void:
	layer = 5
	var rect := ColorRect.new()
	rect.anchor_right  = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var shader := load("res://assets/shaders/vignette.gdshader") as Shader
	if shader == null:
		push_error("VignetteOverlay: shader not found")
		return

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("strength", strength)
	mat.set_shader_parameter("opacity",  opacity)
	rect.material = mat
	add_child(rect)

func set_params(new_strength: float, new_opacity: float) -> void:
	strength = new_strength
	opacity  = new_opacity
	var rect := get_child(0) as ColorRect
	if rect and rect.material:
		(rect.material as ShaderMaterial).set_shader_parameter("strength", strength)
		(rect.material as ShaderMaterial).set_shader_parameter("opacity",  opacity)
