extends Node

@export var turn_manager_path: NodePath = ^"../TurnManager"

var _turn_manager: TurnManager
var _layer: CanvasLayer
var _button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_turn_manager = get_node_or_null(turn_manager_path) as TurnManager
	assert(_turn_manager != null, "EndTurnButton: TurnManager não encontrado")
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_button = Button.new()
	_button.text = "Encerrar turno\n[Enter]"
	_button.focus_mode = Control.FOCUS_NONE
	_button.custom_minimum_size = Vector2(140, 56)
	_button.add_theme_font_size_override("font_size", 16)
	_layer.add_child(_button)
	_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_button.pressed.connect(_on_pressed)


func _process(_delta: float) -> void:
	if get_tree().paused:
		_layer.visible = false
		return
	_layer.visible = true
	_button.disabled = not _can_end_turn()


func _can_end_turn() -> bool:
	if _turn_manager.side != TurnManager.TurnSide.PLAYER:
		return false
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit != null and unit.is_moving:
			return false
	return true


func _on_pressed() -> void:
	if not _can_end_turn():
		return
	for is_pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = is_pressed
		Input.parse_input_event(key)
