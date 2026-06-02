@tool
extends EditorPlugin

var inspectors

func _enter_tree():
	inspectors = load(get_plugin_path() + "/inspectors.gd").new()
	add_inspector_plugin(inspectors)

func _exit_tree():
	remove_inspector_plugin(inspectors)

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()
