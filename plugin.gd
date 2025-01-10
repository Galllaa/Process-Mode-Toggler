@tool
extends EditorPlugin

var button: Button = null
var previous_process_mode: Dictionary = {}

func _enter_tree():
	# Create the button
	button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.connect("pressed", Callable(self, "_on_button_pressed"))
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button)
	
	var editor = get_editor_interface()
	var selection = editor.get_selection()
	selection.connect("selection_changed", Callable(self, "update_button_ui"))

	update_button_ui()

func _exit_tree():
	var editor = get_editor_interface()
	var selection = editor.get_selection()
	selection.disconnect("selection_changed", Callable(self, "update_button_ui"))
	
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, button)
	button.queue_free()

func _on_button_pressed():
	var selected_node = get_selected_node()
	if selected_node:
		var node_id = selected_node.get_instance_id()  # Use unique ID instead of path
		
		if selected_node.process_mode == Node.PROCESS_MODE_DISABLED:
			# Revert to the previous process mode
			if previous_process_mode.has(node_id):
				selected_node.process_mode = previous_process_mode[node_id]
				selected_node.show()
				previous_process_mode.erase(node_id)  # Clean up after reverting
			else:
				selected_node.show()
				selected_node.process_mode = Node.PROCESS_MODE_INHERIT  # Default fallback
		else:
			# Store the current process mode and disable the node
			selected_node.hide()
			previous_process_mode[node_id] = selected_node.process_mode
			selected_node.process_mode = Node.PROCESS_MODE_DISABLED
		
		update_button_ui()

func update_button_ui():
	var selected_node = get_selected_node()
	if selected_node:
		# Update the button color
		if selected_node.process_mode == Node.PROCESS_MODE_DISABLED:
			button.add_theme_color_override("font_color", Color.RED)
		else:
			button.add_theme_color_override("font_color", Color.GREEN)

		# Update the button text
		button.text = "Mode: " + get_process_mode_name(selected_node.process_mode)
	else:
		# Default text and color if no node is selected
		button.text = "Toggle: No Node Selected"
		button.add_theme_color_override("font_color", Color.GRAY)

func get_selected_node() -> Node:
	var editor = get_editor_interface()
	var selected_scene = editor.get_selection().get_selected_nodes()
	if selected_scene.size() > 0:
		return selected_scene[0]
	return null

func get_process_mode_name(mode: int) -> String:
	match mode:
		Node.PROCESS_MODE_INHERIT:
			return "Inherit"
		Node.PROCESS_MODE_DISABLED:
			return "Disabled"
		Node.PROCESS_MODE_ALWAYS:
			return "Always"
		Node.PROCESS_MODE_PAUSABLE:
			return "Paused"
		Node.PROCESS_MODE_WHEN_PAUSED:
			return "When Paused"
		_:
			return "Unknown"
