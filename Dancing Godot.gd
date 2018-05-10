extends Node

onready var material = $TextureRect.material
var amplitude

func _ready():
	# initialise our starting value, note that this can be null if you haven't specified defaults on your material.
	amplitude = material.get_shader_param("amplitude")
	if !amplitude:
		amplitude = Vector2(10.0, 10.0)
	$Amplitude_X.value = amplitude.x

func _on_Amplitude_X_value_changed(value):
	amplitude.x = value
	material.set_shader_param("amplitude", amplitude)
