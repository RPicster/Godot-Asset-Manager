tool
extends VBoxContainer


func _enter_tree():
	$Headline/CheckBox.add_icon_override("checked", get_icon("GuiVisibilityVisible", "EditorIcons"))
	$Headline/CheckBox.add_icon_override("unchecked", get_icon("GuiVisibilityHidden", "EditorIcons"))
	$Headline/CheckBox.set_tooltip("Show / Hide")


func _on_CheckBox_toggled(button_pressed) -> void:
	$HBoxContainer/Children.visible = button_pressed
	$MarginContainer.visible = button_pressed

