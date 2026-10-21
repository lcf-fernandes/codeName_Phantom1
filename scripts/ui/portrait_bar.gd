class_name PortraitBar
extends CanvasLayer
## Faixa de retratos dos soldados no topo da tela: um espaço por soldado (team SQUAD), em ordem
## de nome. Cada espaço tem o retrato (ou um círculo azul com o número), uma barra de vida e uma
## moldura amarela quando o soldado está selecionado. Soldado morto fica cinza, com a barra vazia.
## Clicar em um soldado vivo o seleciona (só no turno do jogador e sem unidade em movimento).

const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (soldado selecionado e select_unit).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o TurnManager (de quem é a vez).
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Lado do retrato, em pixels.
@export var portrait_size: int = 64
## Espaço entre os retratos, em pixels.
@export var slot_spacing: int = 8
## Distância da faixa até o topo da tela, em pixels.
@export var top_margin: int = 12

## Um espaço da faixa (um soldado).
class Slot:
	var unit: Unit
	var holder: Control
	var frame: Panel
	var health_bar: ProgressBar
	var dead: bool = false

var _selection: SelectionController
var _turn_manager: TurnManager
var _row: HBoxContainer
var _slots: Array[Slot] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 4

	_selection = get_node(selection_controller_path) as SelectionController
	_turn_manager = get_node(turn_manager_path) as TurnManager
	assert(_selection != null, "PortraitBar: selection_controller_path não aponta para um SelectionController.")
	assert(_turn_manager != null, "PortraitBar: turn_manager_path não aponta para um TurnManager.")

	_build_row()
	_selection.unit_selected.connect(_on_unit_selected)
	_selection.selection_cleared.connect(_on_selection_cleared)
	# Depois de os soldados existirem (os spawners criam as unidades no _ready deles).
	_build_slots.call_deferred()


# Fileira centralizada no topo; nenhum contêiner captura cliques (só os retratos).
func _build_row() -> void:
	_row = HBoxContainer.new()
	_row.name = "Row"
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", slot_spacing)
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.anchor_top = 0.0
	_row.anchor_bottom = 0.0
	_row.offset_top = top_margin
	_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_row.grow_vertical = Control.GROW_DIRECTION_END
	add_child(_row)


func _build_slots() -> void:
	var soldiers: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Unit.Team.SQUAD:
			soldiers.append(unit)
	soldiers.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_name < b.unit_name)

	for soldier: Unit in soldiers:
		_slots.append(_build_slot(soldier))


func _build_slot(unit: Unit) -> Slot:
	var slot: Slot = Slot.new()
	slot.unit = unit

	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Slot_%s" % unit.unit_name
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	_row.add_child(column)

	# Área do retrato: é a única parte que reage ao clique.
	slot.holder = Control.new()
	slot.holder.name = "Portrait"
	slot.holder.custom_minimum_size = Vector2(portrait_size, portrait_size)
	slot.holder.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.holder.gui_input.connect(_on_holder_gui_input.bind(slot))
	column.add_child(slot.holder)

	if unit.portrait != null:
		var image: TextureRect = TextureRect.new()
		image.texture = unit.portrait
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_fill(image)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.holder.add_child(image)
	else:
		slot.holder.add_child(_make_number_circle(unit))

	# Moldura amarela da seleção, por cima do retrato.
	slot.frame = Panel.new()
	slot.frame.name = "Frame"
	var frame_style: StyleBoxFlat = StyleBoxFlat.new()
	frame_style.draw_center = false
	frame_style.border_color = Color(1.0, 0.85, 0.1)
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(6)
	slot.frame.add_theme_stylebox_override("panel", frame_style)
	_fill(slot.frame)
	slot.frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.frame.visible = unit == _selection.selected_unit
	slot.holder.add_child(slot.frame)

	# Barra de vida fina, sem texto.
	slot.health_bar = ProgressBar.new()
	slot.health_bar.name = "Health"
	slot.health_bar.show_percentage = false
	slot.health_bar.custom_minimum_size = Vector2(portrait_size, 8.0)
	slot.health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.health_bar.min_value = 0.0
	slot.health_bar.max_value = float(unit.max_hp)
	slot.health_bar.value = float(unit.hp)
	column.add_child(slot.health_bar)

	unit.health_changed.connect(_on_health_changed)
	unit.died.connect(_on_unit_died)
	return slot


# Sem imagem: círculo azul com o número da unidade (último caractere do nome).
func _make_number_circle(unit: Unit) -> Control:
	var circle: Panel = Panel.new()
	circle.name = "Circle"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.4, 0.9)
	style.set_corner_radius_all(int(portrait_size * 0.5))
	circle.add_theme_stylebox_override("panel", style)
	_fill(circle)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var number: Label = Label.new()
	number.text = unit.unit_name.right(1)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_theme_font_size_override("font_size", 34)
	number.add_theme_color_override("font_color", Color.WHITE)
	number.add_theme_color_override("font_outline_color", Color.BLACK)
	number.add_theme_constant_override("outline_size", 6)
	_fill(number)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(number)
	return circle


# Ocupa toda a área do pai.
func _fill(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _on_holder_gui_input(event: InputEvent, slot: Slot) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_try_select(slot)


# Só soldado vivo, no turno do jogador, sem unidade em movimento e com a missão em andamento.
func _try_select(slot: Slot) -> void:
	if slot.dead or not is_instance_valid(slot.unit):
		return
	if _turn_manager.side != TurnManager.TurnSide.PLAYER or _is_any_unit_moving() or get_tree().paused:
		return
	_selection.select_unit(slot.unit)


func _on_unit_selected(unit: Unit) -> void:
	for slot: Slot in _slots:
		slot.frame.visible = slot.unit == unit and not slot.dead


func _on_selection_cleared() -> void:
	for slot: Slot in _slots:
		slot.frame.visible = false


func _on_health_changed(unit: Unit, hp: int, max_hp: int) -> void:
	var slot: Slot = _find_slot(unit)
	if slot == null:
		return
	slot.health_bar.max_value = float(max_hp)
	slot.health_bar.value = float(hp)


# O espaço continua no lugar, acinzentado, com a barra vazia e sem reagir a cliques.
func _on_unit_died(unit: Unit) -> void:
	var slot: Slot = _find_slot(unit)
	if slot == null:
		return
	slot.dead = true
	slot.holder.modulate = Color(0.4, 0.4, 0.4, 1.0)
	slot.holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.health_bar.value = 0.0
	slot.frame.visible = false


func _find_slot(unit: Unit) -> Slot:
	for slot: Slot in _slots:
		if slot.unit == unit:
			return slot
	return null


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false
