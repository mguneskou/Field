class_name InputController
extends Node
## Translates raw engine input events into abstract game actions. Nothing
## downstream needs to know whether an action came from a key, a mouse, or
## (later) a touch screen — screen touch/drag already map onto the same
## pointer signals as mouse events.

signal pause_toggled
signal reset_requested
signal menu_requested

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				pause_toggled.emit()
				get_viewport().set_input_as_handled()
			KEY_R:
				reset_requested.emit()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				menu_requested.emit()
				get_viewport().set_input_as_handled()
