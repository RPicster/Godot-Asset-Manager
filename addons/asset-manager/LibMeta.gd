extends Resource
class_name SceneLibraryItem

export var descriptive_name : String
export var icon_texture : Texture
export(String, FILE, "*.tscn") var scene_path : String
export var priority : int
export var hide_in_list : bool
export var path_prefix: String
export var favorite: bool
export var item_color: Color
