tool
extends Control
class_name LibraryCategory

var plugin : EditorPlugin

var LibraryItemScene = load( "res://addons/asset-manager/LibraryItem.tscn" )
var LibrarySectionScene = load( "res://addons/asset-manager/LibrarySection.tscn" )
var LibrarySubSectionScene = load( "res://addons/asset-manager/LibrarySubSection.tscn" )

var filesystem : EditorFileSystem = null
var sections : Array
var subsections : Array
var category_dir : String = ""
var regex = RegEx.new()

onready var container = $Content/ScrollContainer/Entries
onready var filter = $Content/Filter/TextEdit


func _enter_tree():
	regex.compile("^[\\d-]*_")
	$Content/Filter/ShowAllButton.set_tooltip("Show all categories")
	$Content/Filter/HideAllButton.set_tooltip("Hide all categories")
	$Content/Filter/UpdateListButton.set_tooltip("Update all assets")
	$Content/Filter/UpdateListButton.icon = get_icon("Reload", "EditorIcons")
	$Content/Filter/HideAllButton.icon = get_icon("GuiVisibilityHidden", "EditorIcons")
	$Content/Filter/ShowAllButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")


func load_entities():
	var directory = Directory.new()
	
	if !directory.dir_exists( category_dir ):
		printerr("Asset Manager Plugin: Category Dir not found!")
		return
	
	var category_folders = get_directories(category_dir)
	
	if category_folders.empty():
		yield(get_tree(), "idle_frame")
		load_entities()
	
	for i in len(category_folders):
		var category_name:String = filesystem.get_filesystem_path(category_folders[i]).get_name()
		
		var section = LibrarySectionScene.instance()
		sections.append(section)
		
		var results : Array = []
		for result in regex.search_all(category_name):
			results.push_back(result.get_string())
		if !results.empty():
			category_name = category_name.split(results[0])[1]
		
		section.get_node("Headline/CheckBox").text = category_name
		container.add_child(section)
		
		var dir = filesystem.get_filesystem_path( category_folders[i] )
		
		check_for_subcategories( dir, section,  category_folders[i] )
		
		add_entities_in_dir(dir, category_folders[i], section)


func check_for_subcategories( dir:EditorFileSystemDirectory, parent:Object, parent_dir:String ):
	for sd in dir.get_subdir_count():
		var subdir = dir.get_subdir(sd)
		var subdir_name = str(subdir.get_name())
		var subdir_path = str(parent_dir + subdir_name + "/")
		
		var subsection = LibrarySubSectionScene.instance()
		subsections.append(subsection)
		
		var results : Array = []
		for result in regex.search_all(subdir_name):
			results.push_back(result.get_string())
		if !results.empty():
			subdir_name = subdir_name.split(results[0])[1]
		
		subsection.get_node("Headline/CheckBox").text = subdir_name
		parent.get_node("HBoxContainer/Children").add_child(subsection)
		subsection.parent_section = parent
		
		if subdir.get_subdir_count() > 0:
			check_for_subcategories( subdir, subsection, subdir_path )
	
		add_entities_in_dir(subdir, subdir_path, subsection)


func add_entities_in_dir(dir, path, parent):
	for x in dir.get_file_count():
		
		var file = dir.get_file(x)
		var entity_path = str(path, file)
		if !entity_path or !file.get_extension() == "tres":
			continue
		
		var new_entity = load(entity_path)
		if new_entity.hide_in_list:
			continue
		
		var entity_name : String = file
		var descriptive_name : String = new_entity.descriptive_name
		var icon_path : String = new_entity.icon_path
		var scene_path : String = new_entity.scene_path
		var priority : int = new_entity.priority
		var path_prefix : String = new_entity.path_prefix
		var item_color : Color = new_entity.item_color
		
		if entity_path:
			var item = LibraryItemScene.instance()
			item.init(entity_path, icon_path, descriptive_name, path_prefix, scene_path, category_dir, item_color, plugin)
			parent.get_node("HBoxContainer/Children").add_child(item)
			if priority > 0:
				parent.move_child(item, max(0, item.get_index() - priority))


func set_editing_level(value):
	visible = value


func filter_entities(filterString:String):
	if filterString == "":
		_on_ShowAllButton_pressed()
		for s in sections:
			for c in s.get_node("HBoxContainer/Children").get_children():
				c.show()
		for sus in subsections:
			for c in sus.get_node("HBoxContainer/Children").get_children():
				c.show()
		return
	
	for s in sections:
		var count_results = 0
		for c in s.get_node("HBoxContainer/Children").get_children():
			# Skip if it is a sub section
			if c.get_class() != "LibraryItem":
				continue

			if !filterString.capitalize() in c.item_name.capitalize():
				c.hide()
			else:
				c.show()
				count_results += 1
		
		if count_results == 0:
			s.get_node("Headline/CheckBox").pressed = false
		else:
			s.get_node("Headline/CheckBox").pressed = true
			
	for sus in subsections:
		var count_results = 0
		for c in sus.get_node("HBoxContainer/Children").get_children():
			if !filterString.capitalize() in c.item_name.capitalize():
				c.hide()
			else:
				c.show()
				count_results += 1
		if count_results == 0:
			sus.get_node("Headline/CheckBox").pressed = false
		else:
			sus.parent_section.get_node("Headline/CheckBox").pressed = true
			sus.get_node("Headline/CheckBox").pressed = true


func _on_TextEdit_focus_entered():
	if filter.text == "Search":
		filter.text = ""
		filter_entities("")


func _on_TextEdit_text_changed(new_text):
	filter_entities(new_text)


func _on_ShowAllButton_pressed():
	for s in sections:
		s.get_node("Headline/CheckBox").pressed = true
	for sus in subsections:
		sus.get_node("Headline/CheckBox").pressed = true


func _on_HideAllButton_pressed():
	for s in sections:
		s.get_node("Headline/CheckBox").pressed = false
	for sus in subsections:
		sus.get_node("Headline/CheckBox").pressed = false


func update_entries():
	clear()
	load_entities()


func has_meta(path):
	var dir: = filesystem.get_filesystem_path(path)
	for i in dir.get_file_count():
		var file = dir.get_file(i)
		if file == "libmeta.tres":
			return true
	return false


func clear():
	for i in range(container.get_child_count()):
		container.get_child(i).queue_free()
	sections = []
	subsections = []


func get_directories(path, p_abs_paths = true)->Array:
	var dirs = []
	var dir = filesystem.get_filesystem_path(path)
	if !dir:
		prints("Asset Manager Plugin: No Filesystem Dirs found!")
		return dirs
	
	for i in dir.get_subdir_count():
		var subdir = dir.get_subdir(i)
		dirs.append(subdir.get_path())
	return dirs
