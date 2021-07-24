tool
extends PanelContainer

var plugin : EditorPlugin

var CategoryGameObject = preload( "res://addons/asset-manager/LibraryCategoryGameObjects.tscn" )
var target_viewport
var hb:HBoxContainer = null
var asset_manager_dir = "res://addons/asset-manager/asset_manager_resources"
var category_dirs : Array = ["", "", ""]
var active_tab := 0

# Popup dialogs / Variables for "Add Asset Popup"
var respath_dialog : FileDialog
var respath_value : String
var icon_dialog : EditorFileDialog
var icon_value : String
var prio_value : float
var hide_value : bool
var scenepath_value : String
var preset_popup : PopupMenu
var created_texture : ImageTexture
var created_image : Image
var item_color : Color

onready var tabs = $Tabs


func init(_plugin):
	plugin = _plugin
	asset_manager_dir = ProjectSettings.get_setting("gui/asset_manager_plugin/resource_directory")
	
	var directory = Directory.new();
	if directory.dir_exists( asset_manager_dir ):
		var game_objects_dir = asset_manager_dir + "/game_objects/"
		if directory.dir_exists( game_objects_dir ):
			category_dirs[0] = game_objects_dir
		else:
			message("Game Objects - Dir not found!", 2)
		
		var deco_dir = asset_manager_dir + "/deco/"
		if directory.dir_exists( deco_dir ):
			category_dirs[1] = deco_dir
		else:
			message("Deco - Dir not found!", 2)
		
		var levels_dir = asset_manager_dir+"/levels/"
		if directory.dir_exists( levels_dir ):
			category_dirs[2] = levels_dir
		else:
			message("Levels - Dir not found!", 2)
	
	plugin.add_scene_button.get_node("AddSceneButton").connect("pressed", self, "_on_AddSceneButton_pressed")
	
	setup_popups()
	var editor_interface = plugin.get_editor_interface()
	var base_control = editor_interface.get_base_control()
	base_control.add_child(respath_dialog)
	base_control.add_child(icon_dialog)
	setup_tabs()

func _enter_tree() -> void:
	preset_popup = $NewItemPopup/Margin/VBox/HBox/ItemPathPresetButton.get_popup()
	preset_popup.connect("id_pressed", self, "_on_itempath_preset_pressed")
	update_path_preset()


func update_path_preset():
	var presets = ProjectSettings.get_setting("gui/asset_manager_plugin/path_prefix_presets")
	
	preset_popup.clear()
	for p in presets:
		preset_popup.add_item(p)


func setup_tabs() -> void:
	get_viewport()
	
	tabs.set_tab_icon(0, get_icon("ViewportSpeed", "EditorIcons"))
	tabs.set_tab_icon(1, get_icon("Environment", "EditorIcons"))
	tabs.set_tab_icon(2, get_icon("AtlasTexture", "EditorIcons"))
	tabs.set_tab_title(0, "Game Objects")
	tabs.set_tab_title(1, "Deco")
	tabs.set_tab_title(2, "Levels")
	
	var tabs_to_update = tabs.get_children()
	
	for i in len(tabs_to_update):
		tabs_to_update[i].plugin = plugin
		tabs_to_update[i].filesystem = plugin.get_editor_interface().get_resource_filesystem()
		tabs_to_update[i].category_dir = category_dirs[i]
	for i in tabs_to_update:
		i.update_entries()


func get_current_viewport():
	if !get_tree().get_edited_scene_root():
		return
	var editor_viewport = get_tree().get_edited_scene_root().get_parent()
	
	if editor_viewport is Viewport:
		target_viewport = editor_viewport
	elif editor_viewport is ViewportContainer:
		target_viewport = get_tree().get_edited_scene_root()
	else:
		target_viewport = editor_viewport.get_parent()


func _exit_tree() -> void:
	if respath_dialog:
		respath_dialog.free()
	if icon_dialog:
		icon_dialog.free()


func setup_popups() -> void:
	var cat_tabs = $NewItemPopup/Margin/VBox/CategoryTabs
	cat_tabs.set_tab_icon(0, get_icon("ViewportSpeed", "EditorIcons"))
	cat_tabs.set_tab_icon(1, get_icon("Environment", "EditorIcons"))
	cat_tabs.set_tab_icon(2, get_icon("AtlasTexture", "EditorIcons"))
	cat_tabs.set_tab_title(0, "Game Objects")
	cat_tabs.set_tab_title(1, "Deco")
	cat_tabs.set_tab_title(2, "Levels")
	$NewItemPopup/Margin/VBox/ResPathButton.icon = get_icon("FolderMediumThumb", "EditorIcons")
	
	respath_dialog = FileDialog.new()
	respath_dialog.mode = FileDialog.MODE_OPEN_DIR
	respath_dialog.access = FileDialog.ACCESS_RESOURCES
	respath_dialog.current_dir = asset_manager_dir + "/"
	respath_dialog.current_path = asset_manager_dir + "/"
	respath_dialog.connect("dir_selected", self, "_on_respath_select")
	
	icon_dialog = EditorFileDialog.new()
	icon_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	icon_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	var icon_dialog_filters : PoolStringArray = ["*.png ; PNG Images"]
	icon_dialog.add_filter("*.jpg, *.jpeg, *.png; Images")
	icon_dialog.connect("file_selected", self, "_on_icon_select")


func create_thumbnail() -> void:
	get_current_viewport()
	var img = target_viewport.get_texture().get_data()
	var img_size = img.get_size()
	img.flip_y()
	if img_size.x > img_size.y:
		img.crop(img_size.y, img_size.y)
	else:
		img.crop(img_size.x, img_size.x)
	
	img.resize(64,64)
	
	var texture = ImageTexture.new()
	texture.create_from_image(img)

	created_texture = texture
	created_image = img
	$NewItemPopup/Margin/VBox/IconButton.icon = texture


func _on_AddSceneButton_pressed() -> void:
	create_thumbnail()
	scenepath_value = get_tree().edited_scene_root.filename
	_new_asset_popup_cat_tab_changed( $NewItemPopup/Margin/VBox/CategoryTabs.current_tab )
	$NewItemPopup/Margin/VBox/HBoxContainer/ColorPickerButton.color = Color.black
	$NewItemPopup/Margin/VBox/HBoxContainer/ShowCheckBox.pressed = true
	$NewItemPopup/Margin/VBox/Title.text = scenepath_value
	$NewItemPopup.popup_centered_ratio(0.4)
	$NewItemPopup/Margin/VBox/HBoxContainer/PrioSpinBox.apply()


func _on_ResPathButton_pressed() -> void:
	respath_dialog.popup_centered_ratio(0.5)


func _on_IconButton_pressed() -> void:
	icon_dialog.popup_centered_ratio(0.5)


func _on_respath_select( _filepath:String ) -> void:
	var is_path_in_asset_manager_dir := false
	for p in category_dirs:
		if p in _filepath:
			is_path_in_asset_manager_dir = true
	
	if !is_path_in_asset_manager_dir:
		_new_asset_popup_cat_tab_changed( $NewItemPopup/Margin/VBox/CategoryTabs.current_tab )
		
	respath_value = _filepath
	$NewItemPopup/Margin/VBox/ResPathButton.text = _filepath.replace(asset_manager_dir, "")


func _on_icon_select( _filepath:String ) -> void:
	icon_value = _filepath
	$NewItemPopup/Margin/VBox/IconButton.icon = load(_filepath)


func _on_PrioSpinBox_value_changed( value ) -> void:
	prio_value = int(value)


func _on_NewItemPopup_confirmed() -> void:
	var descr_name = $NewItemPopup/Margin/VBox/DescrLineEdit.text
	var file_name = descr_name.to_lower().replace(" ", "_").replace("-", "_")
	
	if $NewItemPopup/Margin/VBox/IconButton.icon == created_texture:
		icon_value = respath_value + "/" + file_name + "_icon.png"
		created_image.save_png(icon_value)
		plugin.get_editor_interface().get_resource_filesystem().update_file(icon_value)
		plugin.get_editor_interface().get_resource_filesystem().scan()
		yield(plugin.get_editor_interface().get_resource_filesystem(), "resources_reimported")

	var new_library_entry : SceneLibraryItem = SceneLibraryItem.new()
	new_library_entry.descriptive_name = descr_name
	new_library_entry.icon_texture = load( icon_value )
	new_library_entry.scene_path = scenepath_value
	new_library_entry.priority = prio_value
	new_library_entry.hide_in_list = hide_value
	new_library_entry.favorite = false
	new_library_entry.item_color = item_color
	new_library_entry.path_prefix = $NewItemPopup/Margin/VBox/HBox/ItemPathLineEdit.text
	
	ResourceSaver.save(respath_value + "/" + file_name + ".tres", new_library_entry, 0)
	scenepath_value = ""
	yield(get_tree(), "idle_frame")
	tabs.get_current_tab_control().update_entries()


func _on_ShowCheckBox_toggled( button_pressed ) -> void:
	hide_value = !button_pressed


func _on_itempath_preset_pressed( id:int ) -> void:
	$NewItemPopup/Margin/VBox/HBox/ItemPathLineEdit.text = preset_popup.get_item_text(id)


func _on_SavePresetButton_pressed():
	if $NewItemPopup/Margin/VBox/HBox/ItemPathLineEdit.text == "":
		return
	var new_presets = ProjectSettings.get_setting("gui/asset_manager_plugin/path_prefix_presets")
	new_presets.append( $NewItemPopup/Margin/VBox/HBox/ItemPathLineEdit.text )
	ProjectSettings.set_setting("gui/asset_manager_plugin/path_prefix_presets", new_presets)
	
	update_path_preset()


func message( text:String, priority : int = 0 ) -> void:
	var basetext = "Asset Manager Plugin: "
	if priority == 0:
		print( basetext + text )
	elif priority == 1:
		push_warning( basetext + text)
	elif priority == 2:
		printerr( basetext + text)

# Still work in progress
#func editItem( resource_file_path:String, folder_path:String ) -> void:
#	folder_path += "/"
#	var item = load( resource_file_path )
#	scenepath_value = item.get_path()
#	var item_paths : Array = resource_file_path.split(folder_path)
#
#	respath_dialog.current_dir = item_paths[0] + folder_path
#	respath_dialog.current_path = item_paths[0] + folder_path
#	$NewItemPopup/Margin/VBox/ResPathButton.text = item_paths[0].replace(asset_manager_dir, "") + folder_path
#	$NewItemPopup/Margin/VBox/Title.text = item.scene_path
#	$NewItemPopup/Margin/VBox/HBoxContainer/ColorPickerButton.color = item.item_color
#	$NewItemPopup/Margin/VBox/HBoxContainer/ShowCheckBox.pressed = !item.hide_in_list
#	$NewItemPopup/Margin/VBox/HBox/ItemPathLineEdit.text = item.path_prefix
#	$NewItemPopup/Margin/VBox/DescrLineEdit.text = item.descriptive_name
#	$NewItemPopup/Margin/VBox/IconButton.icon = item.icon_texture
#	$NewItemPopup/Margin/VBox/HBoxContainer/PrioSpinBox.value = item.priority
#	$NewItemPopup/Margin/VBox/HBoxContainer/PrioSpinBox.apply()
#	$NewItemPopup.popup_centered_ratio(0.4)
#	$NewItemPopup/Margin/VBox/HBoxContainer/PrioSpinBox.apply()


func _new_asset_popup_cat_tab_changed(tab):
	respath_dialog.current_dir = category_dirs[ tab ]
	respath_dialog.current_path = category_dirs[ tab ]
	_on_respath_select( category_dirs[ tab ] )


func _Popup_ColorPicker_changed(color):
	item_color = color


func get_canvas_scale() -> Vector2:
	get_current_viewport()
	return Vector2.ONE * target_viewport.global_canvas_transform.x.x



func _on_NewItemPopup_popup_hide():
	print("hidden")
