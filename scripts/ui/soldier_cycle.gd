extends Node

@export var selection_controller_path: NodePath = ^"../SelectionController"
@export var turn_manager_path: NodePath = ^"../TurnManager"

var _selection: SelectionController
var _turn_manager: TurnManager


func _ready() -> void:
	_selection = get_node_or_null(selection_controller_path) as SelectionController
	_turn_manager = get_node_or_null(turn_manager_path) as TurnManager
	assert(_selection != null, "SoldierCycle: SelectionController não encontrado")
	assert(_turn_manager != null, "SoldierCycle: TurnManager não encontrado")


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_TAB:
		return
	get_viewport().set_input_as_handled()
	_cycle(-1 if key.shift_pressed else 1)


func _cycle(direction: int) -> void:
	if _turn_manager.side != TurnManager.TurnSide.PLAYER:
		return
	var soldiers: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null:
			continue
		if unit.is_moving:
			return
		if unit.team == Unit.Team.SQUAD and unit.hp > 0 and unit.action_points > 0:
			soldiers.append(unit)
	if soldiers.is_empty():
		print("Tab: nenhum soldado com PA")
		return
	soldiers.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_name < b.unit_name)
	var index := soldiers.find(_selection.selected_unit)
	var next_index: int
	if index == -1:
		next_index = 0 if direction > 0 else soldiers.size() - 1
	else:
		next_index = posmod(index + direction, soldiers.size())
	_selection.select_unit(soldiers[next_index])
