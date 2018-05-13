extends Sprite

func _ready():
	material.set_shader_param("aspect_ratio", scale.y/scale.x)

