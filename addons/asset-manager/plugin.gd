tool
extends EditorPlugin

var library : PanelContainer = null
var add_scene_button : Control = null

var placing_entity_item : LibraryItem
var placing_previewer : CanvasLayer

var alt_key_pressed := false
var shift_key_pressed := false
var regex = RegEx.new()


func _ready() -> void:
	add_custom_type("LibraryMeta", "Resource", preload("LibMeta.gd"), get_editor_interface().get_base_control().theme.get_icon("ResourcePreloader", 'EditorIcons'))
	placing_previewer = load( "res://addons/asset-manager/PlacingPreviewer.tscn" ).instance()
	placing_previewer.play_sound = ProjectSettings.get_setting("gui/asset_manager_plugin/play_sound")
	get_tree().root.call_deferred("add_child", placing_previewer)


func _enter_tree() -> void:
	regex.compile("^[\\d-]*_")
	_add_setting("gui/asset_manager_plugin/resource_directory", TYPE_STRING, "res://addons/asset-manager/asset_manager_resources" , PROPERTY_HINT_DIR)
	_add_setting("gui/asset_manager_plugin/path_prefix_presets", TYPE_STRING_ARRAY, [])
	_add_setting("gui/asset_manager_plugin/pixel_snapping", TYPE_BOOL, true)
	_add_setting("gui/asset_manager_plugin/play_sound", TYPE_BOOL, true)
	
	library = load( "res://addons/asset-manager/Library.tscn" ).instance()
	add_scene_button = load( "res://addons/asset-manager/LibraryAddScene.tscn" ).instance()
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, library)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, add_scene_button)
	library.init(self)


func _add_setting(name:String, type, value, hint := PROPERTY_HINT_NONE):
	if ProjectSettings.has_setting(name):
		return
	
	ProjectSettings.set(name, value)
	var property_info = {
		"name": name,
		"type": type,
		"hint": hint
	}
	ProjectSettings.add_property_info(property_info)


func _exit_tree() -> void:
	remove_control_from_docks(library)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, add_scene_button)
	add_scene_button.free()
	library.free()
	placing_previewer.free()
	remove_custom_type("LibraryMeta")


func _input(event) -> void:
	if placing_entity_item == null:
		return
	
	if event is InputEventKey and event.scancode == 16777240:
		alt_key_pressed = event.pressed
	
	if event is InputEventKey and event.scancode == 16777237:
		shift_key_pressed = event.pressed
	
	if event is InputEventKey and event.scancode == 16777217 and event.pressed:
		cancel_drag()
		return
	
	if event is InputEventKey and event.scancode == 16777238 and !event.pressed:
		placing_previewer.switch_preview_mode( !placing_previewer.instance_preview_mode, library.get_canvas_scale() )
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed:
			stop_drag()
		if event.button_index == BUTTON_RIGHT and !event.pressed:
			cancel_drag()


func start_drag( entity_item : LibraryItem ) -> void:
	placing_entity_item = entity_item
	placing_previewer.set_preview( entity_item.icon_texture, entity_item.descriptive_name, entity_item.scene_path )


func stop_drag() -> void:
	if placing_entity_item:
		var instance_parent = null
		if !alt_key_pressed:
			instance_parent = get_entity_parent(placing_entity_item)
		else:
			var selected_nodes : Array = get_editor_interface().get_selection().get_selected_nodes()
			if !selected_nodes.empty():
				instance_parent = selected_nodes[0]
		
		if !instance_parent:
			if !get_tree().edited_scene_root:
				cancel_drag()
				return
			else:
				instance_parent = get_tree().edited_scene_root
		
		var instance = load(placing_entity_item.scene_path).instance()
		instance_parent.add_child(instance, true)
		instance.set_owner(get_tree().edited_scene_root)
		
		if ProjectSettings.get_setting("gui/asset_manager_plugin/pixel_snapping"):
			instance.position = get_tree().edited_scene_root.get_local_mouse_position().round()
		else:
			instance.position = get_tree().edited_scene_root.get_local_mouse_position()
		instance.global_rotation = placing_previewer.scene.rotation
		
		if !shift_key_pressed:
			var selection = get_editor_interface().get_selection()
			selection.clear()
			selection.add_node(instance)
			placing_entity_item = null
			placing_previewer.place(true)
		else:
			placing_previewer.place(false)


func cancel_drag() -> void:
	var selection = get_editor_interface().get_selection()
	selection.clear()
	placing_entity_item = null
	placing_previewer.cancel_placement()


func get_entity_parent( item : LibraryItem ) -> Node2D:
	var path_prefix : String = item.path_prefix.trim_prefix("/").trim_suffix("/")
	var asset_manager_path = remove_prefix(item.folder_path)
	var full_path : String = asset_manager_path
	
	if path_prefix != "":
		full_path = path_prefix + "/" + asset_manager_path
	
	var scene = get_tree().edited_scene_root
	
	if scene.has_node(full_path):
		return scene.get_node(full_path)
	
	var folders = full_path.split("/")
	var current_folder = ""
	var parent_obj = scene
	
	for folder in folders:
		if current_folder == "":
			current_folder += folder
		else:
			current_folder += "/" + folder
		
		if scene.has_node(current_folder):
			parent_obj = scene.get_node(current_folder)
			continue
		else:
			var node:Node2D = Node2D.new()
			parent_obj.add_child(node, true)
			node.set_owner(scene)
			node.name = remove_prefix(folder)
			parent_obj = node
	
	return parent_obj


func remove_prefix(_string:String) -> String:
	var results : Array = []
	for result in regex.search_all(_string):
		results.push_back(result.get_string())
	if !results.empty():
		_string = _string.split(results[0])[1]
	return _string
