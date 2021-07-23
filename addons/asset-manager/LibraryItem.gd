tool
extends HBoxContainer
class_name LibraryItem

var plugin:EditorPlugin
var resource_file_path:String
var icon_texture:Texture
var path_prefix:String
var scene_path:String
var descriptive_name:String
var folder_path:String

onready var popup = $PopupMenu
onready var delete_popup = $DeletePopup

func init( _file_path, _icon_tex:Texture, _descriptive_name:String, _path_prefix:String, _scene_path:String, _category_dir:String, _color:Color, _plugin:EditorPlugin ) -> void:
	resource_file_path = _file_path
	plugin = _plugin
	path_prefix = _path_prefix
	scene_path = _scene_path
	descriptive_name = _descriptive_name
	$Item.text = descriptive_name
	if _color == Color.black:
		$ColorRect.hide()
	else:
		$ColorRect.color = _color
	folder_path = _file_path.get_base_dir().replace(_category_dir, "")
	
	if _icon_tex:
		icon_texture = _icon_tex
		$Item.icon = _icon_tex


func _ready() -> void :
	popup.items[0] = descriptive_name
	popup.set_item_icon(2, get_icon("CanvasItem", "EditorIcons"))
	popup.set_item_icon(3, get_icon("Remove", "EditorIcons"))
	popup.set_item_icon(4, get_icon("ActionCopy", "EditorIcons"))
	popup.set_item_icon(5, get_icon("Search", "EditorIcons"))

func _enter_tree() -> void:
	$OpenScene.icon = get_icon("PackedScene", "EditorIcons")


func _on_LibraryItem_button_down() -> void:
	plugin.start_drag(self)
	release_focus()


func _on_OpenScene_pressed() -> void:
	plugin.get_editor_interface().open_scene_from_path( scene_path )


func _on_LibraryItem_mouse_entered():
	$OpenScene.show()


func _on_LibraryItem_mouse_exited():
	$OpenScene.hide()


func _on_Item_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and !event.pressed:
		popup.rect_position = get_global_mouse_position()
		popup.popup()


func _on_PopupMenu_id_pressed(id):
	if id == 5:
		plugin.get_editor_interface().select_file( scene_path )
	elif id == 4:
		OS.set_clipboard( scene_path )
	elif id == 3:
		delete_popup.rect_position = popup.rect_position
		delete_popup.popup()


func delete_from_asset_library():
	var directory = Directory.new()
	
	if icon_texture and icon_texture != null:
		if directory.file_exists(icon_texture.get_path()):
			var error = directory.remove( icon_texture.get_path() )
			if error:
				print("Asset Manager: Error deleting Image File!")
			else:
				plugin.get_editor_interface().get_resource_filesystem().update_file( icon_texture.get_path() )
		else:
			print("Asset Manager: Image File not found")

	if directory.file_exists(resource_file_path):
		var error = directory.remove(resource_file_path)
		if error:
			print("Asset Manager: Error deleting File!")
		else:
			plugin.get_editor_interface().get_resource_filesystem().update_file(resource_file_path)
			plugin.library.update_entries()
	else:
		print("Asset Manager: File not found")


func _cancel_delete():
	delete_popup.hide()
