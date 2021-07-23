tool
extends CanvasLayer

var previous_mouse_position : Vector2
var angular_velocity : float
var scene_path := ""
var instance_preview_mode := false
var is_active := false
var play_sound := false

onready var preview = $Preview
onready var scene = $InstancePreview/Scene
onready var info = $InstancePreview/Info
onready var instance_preview = $InstancePreview
onready var audio_drop = $Preview/AudioDrop
onready var audio_drag = $Preview/AudioDrag
onready var tween = $Preview/Tween


func _ready() -> void:
	set_process(false)
	preview.hide()
	


func _process( delta:float ) -> void:
	var mouse_position: = get_viewport().get_mouse_position()
	preview.position = mouse_position
	var mouse_velocity = (mouse_position - previous_mouse_position)
	preview.rotation += mouse_velocity.x / 300
	angular_velocity = elastic(preview.rotation, 0, angular_velocity, .9, .1)
	preview.rotation += angular_velocity * delta * 20
	previous_mouse_position = mouse_position
	instance_preview.position = preview.position


func _input(event):
	if !is_active:
		return
	
	if event is InputEventMouseButton and !event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			scene.rotation_degrees = wrapf(scene.rotation_degrees-15, -360, 360)
			info.text = "Rot: " + str(round(scene.rotation_degrees))
		elif event.button_index == BUTTON_WHEEL_DOWN:
			scene.rotation_degrees = wrapf(scene.rotation_degrees+15, -360, 360)
			info.text = "Rot: " + str(round(scene.rotation_degrees))


func set_preview( texture:Texture, descr:String, _scene_path:String ) -> void:
	preview.show()
	angular_velocity = 0
	preview.rotation = 0
	scene_path = _scene_path
	$Preview/Label.text = descr
	if texture != null:
		$Preview/TextureRect.texture = texture
	else:
		$Preview/TextureRect.texture = null
	set_process(true)
	is_active = true
	if play_sound:
		audio_drag.play()
	previous_mouse_position = get_viewport().get_mouse_position()


func switch_preview_mode( value:bool, canvas_scale:Vector2 ):
	if instance_preview_mode != value:
		instance_preview_mode = value
		$Preview.visible = !value
		$InstancePreview.visible = value
		if value and scene.get_child_count() == 0:
			instance_preview.show()
			info.text = ""
			var new_preview = load(scene_path).instance()
			new_preview.scale = canvas_scale
			scene.add_child(new_preview)
		else:
			for c in scene.get_children():
				c.queue_free()


func place( stop_placement:bool ) -> void:
	if play_sound:
		audio_drop.pitch_scale = 1 + randf() * .15
		audio_drop.play()
	tween.remove_all()
	tween.interpolate_property(preview, "scale", Vector2(0.4,0.4), Vector2.ONE, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	if stop_placement:
		stop()


func cancel_placement() -> void:
	if play_sound:
		audio_drop.pitch_scale = 0.5 + randf() * .15
		audio_drop.play()
	stop()
	

func stop() -> void:
	set_preview( null, "", "" )
	switch_preview_mode(false, Vector2.ONE)
	is_active = false
	set_process(false)
	scene.rotation = 0
	preview.hide()
	instance_preview.hide()


func elastic(from:float, to:float, elastic_value:float, speed:float = .8, friction:float = .2) -> float:
	return (elastic_value * speed) + ((to - from) * friction);
