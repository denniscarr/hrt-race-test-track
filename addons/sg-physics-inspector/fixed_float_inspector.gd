class_name FixedFloatInspector extends EditorProperty

var spinbox: SpinBox
var float_button: Button
var value: int = 0

# example output for the value [98304]: "1.50"
var readable_value: String:
	get: return " %0.2f" % (float(value)/65536)

func _init(object: Object, property_name: String):
	value = object[property_name]

	spinbox = SpinBox.new()
	# limit to 10 000 in both ways, to avoid integer wrapping 
	# people are probably doing something dangerous if they choose to exceed this
	spinbox.min_value = -655360000
	spinbox.max_value =  655360000
	spinbox.custom_arrow_step = 655 # .01 in float steps (inprecise)
	spinbox.value = object.get(property_name)
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.value_changed.connect(on_spinbox_changed)
	
	float_button = Button.new()
	float_button.custom_minimum_size = Vector2(60,0)
	float_button.flat = true
	float_button.text = readable_value
	float_button.pressed.connect(edit_as_float)
	
	var hbox := HBoxContainer.new()
	hbox.add_child(float_button)
	hbox.add_child(spinbox)
	add_child(hbox)

func edit_as_float():
	#grab focus and wait until fully grabbed (hacky, but not sure how to approach properly)
	var line_edit = spinbox.get_line_edit()
	line_edit.grab_focus()
	for i in range(5):
		await get_tree().process_frame
	
	#get shortest version of float as string
	var float_string = readable_value.strip_edges()
	for i in range(3):
		if (float_string.ends_with("0") or float_string.ends_with(".")):
			float_string = float_string.left(-1)
		else: continue
	
	#place float string into line_edit and move caret to end of its location
	line_edit.text = str(float_string, " * 65536")
	line_edit.caret_column = float_string.length()
	line_edit.text_changed.emit()

func on_spinbox_changed(new_value: int):
	value = new_value
	float_button.text = readable_value
	emit_changed(get_edited_property(), value)

func _update_property():
	var new_value = get_edited_object()[get_edited_property()]
	value = new_value

func _property_can_revert(property: StringName) -> bool:
	return false
	
func property_can_revert_changed(property: StringName, can_revert: bool) -> bool:
	return false
