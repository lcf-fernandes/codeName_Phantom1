class_name TurnHud
extends CanvasLayer
## Mostra o turno atual e, com um soldado selecionado, os pontos de ação dele.
## Canto superior esquerdo: "Turno N · Jogador|Inimigos" e "<nome>: PA x/y".

## Caminho até o TurnManager.
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Caminho até o SelectionController.
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o TargetPreview (texto de cobertura do inimigo sob o mouse).
@export var target_preview_path: NodePath = ^"../TargetPreview"
## Tamanho da fonte do texto.
@export var font_size: int = 22

var _turn_manager: TurnManager
var _selection: SelectionController
var _target_preview: TargetPreview
var _label: Label


func _ready() -> void:
	_turn_manager = get_node(turn_manager_path) as TurnManager
	_selection = get_node(selection_controller_path) as SelectionController
	_target_preview = get_node(target_preview_path) as TargetPreview
	assert(_turn_manager != null, "TurnHud: turn_manager_path não aponta para um TurnManager.")
	assert(_selection != null, "TurnHud: selection_controller_path não aponta para um SelectionController.")
	assert(_target_preview != null, "TurnHud: target_preview_path não aponta para um TargetPreview.")

	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(16.0, 12.0)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_refresh()


# O texto é recomposto a cada quadro, então acompanha qualquer mudança
# (turno, seleção e PA); o Label só é alterado quando o texto muda.
func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var side_name: String = "Jogador" if _turn_manager.side == TurnManager.TurnSide.PLAYER else "Inimigos"
	var text: String = "Turno %d · %s" % [_turn_manager.turn_number, side_name]

	var unit: Unit = _selection.selected_unit
	if unit != null:
		text += "\n%s: PA %d/%d" % [unit.unit_name, unit.action_points, unit.max_action_points]

	if not _target_preview.hover_text.is_empty():
		text += "\n" + _target_preview.hover_text

	if _label.text != text:
		_label.text = text
