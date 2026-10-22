class_name ActionBar
extends CanvasLayer
## Barra de ações no rodapé, montada em código: nome do soldado selecionado e os botões
## Atacar [1], Defender [2] e Vigilância [3]. "Atacar" liga o modo de mira, "Defender" gasta os PA
## restantes e deixa o soldado em guarda; "Vigilância" ainda não existe.

const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (soldado selecionado).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o TurnManager (de quem é a vez).
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Caminho até o AttackController (custo de PA do ataque).
@export var attack_controller_path: NodePath = ^"../AttackController"
## Caminho até o CombatCalc (distância entre células).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## Distância da barra até a borda de baixo da tela, em pixels.
@export var bottom_margin: int = 16
## Tamanho da fonte do nome do soldado.
@export var name_font_size: int = 30
## Tamanho da fonte do aviso do modo de mira.
@export var warning_font_size: int = 24

var _selection: SelectionController
var _turn_manager: TurnManager
var _attack: AttackController
var _combat_calc: CombatCalc

var _bar: PanelContainer
var _name_label: Label
var _attack_button: Button
var _defend_button: Button
var _warning: Label


func _ready() -> void:
	# Continua rodando com o jogo pausado: ao fim da missão a barra precisa se esconder.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5

	_selection = get_node(selection_controller_path) as SelectionController
	_turn_manager = get_node(turn_manager_path) as TurnManager
	_attack = get_node(attack_controller_path) as AttackController
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	assert(_selection != null, "ActionBar: selection_controller_path não aponta para um SelectionController.")
	assert(_turn_manager != null, "ActionBar: turn_manager_path não aponta para um TurnManager.")
	assert(_attack != null, "ActionBar: attack_controller_path não aponta para um AttackController.")
	assert(_combat_calc != null, "ActionBar: combat_calc_path não aponta para um CombatCalc.")

	_build_ui()
	_attack.attack_mode_changed.connect(_on_attack_mode_changed)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


# As teclas 1 e 2 fazem o mesmo que os botões Atacar e Defender, se a barra estiver visível e o botão habilitado.
func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if not _bar.visible:
		return
	if key_event.keycode == KEY_1 or key_event.keycode == KEY_KP_1:
		if _attack_button.disabled:
			return
		_on_attack_pressed()
	elif key_event.keycode == KEY_2 or key_event.keycode == KEY_KP_2:
		if _defend_button.disabled:
			return
		_on_defend_pressed()
	else:
		return
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	# Barra ancorada no centro, embaixo; cresce para cima e para os lados conforme o conteúdo.
	_bar = PanelContainer.new()
	_bar.name = "Bar"
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_top = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_bottom = -bottom_margin
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.8)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_bar.add_theme_stylebox_override("panel", style)
	add_child(_bar)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	_bar.add_child(row)

	# À esquerda: o nome do soldado selecionado.
	_name_label = Label.new()
	_name_label.name = "SoldierName"
	_name_label.custom_minimum_size = Vector2(230.0, 0.0)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", name_font_size)
	row.add_child(_name_label)

	# Ao centro: os três botões.
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	row.add_child(buttons)

	_attack_button = _make_button("Atacar [1]", buttons)
	_attack_button.name = "AttackButton"
	# Modo alternado: só assim o botão pode aparecer pressionado enquanto o modo de mira está ligado.
	_attack_button.toggle_mode = true
	_attack_button.pressed.connect(_on_attack_pressed)

	_defend_button = _make_button("Defender [2]", buttons)
	_defend_button.name = "DefendButton"
	_defend_button.pressed.connect(_on_defend_pressed)

	var overwatch_button: Button = _make_button("Vigilância [3]", buttons)
	overwatch_button.name = "OverwatchButton"
	overwatch_button.disabled = true
	overwatch_button.tooltip_text = "Em breve"

	# Aviso do modo de mira, centralizado logo acima da barra (a posição é ajustada no _refresh).
	_warning = Label.new()
	_warning.name = "AimWarning"
	_warning.text = "Selecione um alvo · Esc cancela"
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.anchor_left = 0.5
	_warning.anchor_right = 0.5
	_warning.anchor_top = 1.0
	_warning.anchor_bottom = 1.0
	_warning.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_warning.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning.add_theme_font_size_override("font_size", warning_font_size)
	_warning.add_theme_color_override("font_color", Color.WHITE)
	_warning.add_theme_color_override("font_outline_color", Color.BLACK)
	_warning.add_theme_constant_override("outline_size", 8)
	_warning.visible = false
	add_child(_warning)

# Sem foco: Enter e Espaço não podem "apertar" um botão (o Enter encerra o turno).
func _make_button(label_text: String, parent: Control) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(160.0, 54.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	parent.add_child(button)
	return button


# Visível só com soldado selecionado, no turno do jogador, sem unidade em movimento e com a
# missão em andamento (o fim da missão pausa o jogo).
func _refresh() -> void:
	var soldier: Unit = _selection.selected_unit
	var show_bar: bool = soldier != null and is_instance_valid(soldier) \
			and _turn_manager.side == TurnManager.TurnSide.PLAYER \
			and not _is_any_unit_moving() and not get_tree().paused
	_bar.visible = show_bar
	# O aviso só aparece com o modo de mira ligado e a barra visível.
	_warning.visible = show_bar and _attack.attack_mode
	if not show_bar:
		return

	_warning.offset_bottom = -(bottom_margin + _bar.size.y + 8.0)
	_name_label.text = soldier.unit_name
	# Com o modo de mira ligado o botão continua habilitado, para poder cancelar.
	_attack_button.disabled = not (_attack.attack_mode or _can_attack(soldier))
	_defend_button.disabled = not _can_defend(soldier)


# Há PA suficiente para atacar e pelo menos um inimigo vivo ao alcance do soldado.
func _can_attack(soldier: Unit) -> bool:
	if soldier.action_points < _attack.attack_cost:
		return false
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or unit.team != Unit.Team.ENEMY or unit.hp <= 0:
			continue
		if _combat_calc.get_distance(soldier.cell, unit.cell) <= soldier.attack_range:
			return true
	return false


func _on_attack_pressed() -> void:
	_attack.toggle_attack_mode()
	# O clique inverte o botão sozinho; se o modo não mudou (não pôde entrar), desfaz a inversão.
	_attack_button.set_pressed_no_signal(_attack.attack_mode)


# Pode defender: PA >= 1 e ainda não está defendendo (a barra já só aparece no turno do jogador,
# sem unidade em movimento).
func _can_defend(soldier: Unit) -> bool:
	return soldier.action_points >= 1 and not soldier.is_defending


# Defender: cancela o modo de mira (sem redesenhar as células), o soldado guarda a posição e a
# seleção é refeita para atualizar HUD, células e barra, como depois de um ataque.
func _on_defend_pressed() -> void:
	var soldier: Unit = _selection.selected_unit
	if soldier == null or not is_instance_valid(soldier) or not _can_defend(soldier):
		return
	if _attack.attack_mode:
		_attack.cancel_attack_mode(false)
	if soldier.defend():
		_selection.select_unit(soldier)


# Mantém o botão Atacar pressionado enquanto o modo de mira está ligado, sem disparar o clique.
func _on_attack_mode_changed(active: bool) -> void:
	_attack_button.set_pressed_no_signal(active)


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false
