extends EditorInspectorPlugin

func _can_handle(object):
	return true

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if (type != TYPE_INT): return false
	
	#handle SG Nodes
	if (hint_type == 0  and is_sg_node_property(object, name)):
		add_property_editor(name, FixedFloatInspector.new(object, name))
		return true
	
	# handle properties in custom scripts
	# example: @export_custom(0,"static_float") var launch_speed: int = 10 * 65536
	match hint_string.to_lower():
		"float", "static_float": 
			add_property_editor(name, FixedFloatInspector.new(object, name))
			return true
	
	#no match
	return false

func is_sg_node_property(object: Object, property_name: String) -> bool:
	#check if this is a custom script
	if (object.get_script()): 
		# only mark default properties for SGFixedNode as fixed floats
		return property_name.to_lower().begins_with("fixed") or property_name.to_lower().begins_with("_fixed")
	return object is SGFixedNode2D or object is SGShape2D
