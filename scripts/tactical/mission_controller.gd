class_name MissionController
extends Node
## Condição de vitória e derrota. Só avalia depois de uma morte (nunca no início da fase) e
## só decide uma vez: sem inimigos vivos = VITÓRIA; sem soldados vivos = DERROTA.
## Ao decidir, mostra um letreiro, pausa o jogo e espera R para reiniciar a fase.

const UNITS_GROUP: StringName = &"units"

## Caminho até o TurnManager (número do turno no texto final).
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Camada do letreiro (CanvasLayer).
@export var overlay_layer: int = 10

var _turn_manager: TurnManager
var _finished: bool = false


func _ready() -> void:
	# Continua funcionando com o jogo pausado (para o R reiniciar a fase).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_turn_manager = get_node(turn_manager_path) as TurnManager
	assert(_turn_manager != null, "MissionController: turn_manager_path não aponta para um TurnManager.")
	# Adiado: as unidades são criadas pelos spawners e precisam existir antes de conectar.
	_connect_units.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not _finished:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo or key_event.keycode != KEY_R:
		return
	get_tree().paused = false
	get_tree().reload_current_scene()


func _connect_units() -> void:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null:
			unit.died.connect(_on_unit_died)


# Adiado para não rodar no meio do tratamento da morte (a unidade ainda está sendo removida).
func _on_unit_died(_unit: Unit) -> void:
	_evaluate.call_deferred()


func _evaluate() -> void:
	if _finished:
		return

	var living_soldiers: int = 0
	var living_enemies: int = 0
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or unit.hp <= 0:
			continue
		if unit.team == Unit.Team.SQUAD:
			living_soldiers += 1
		else:
			living_enemies += 1

	if living_enemies == 0:
		_finish(true)
	elif living_soldiers == 0:
		_finish(false)


func _finish(victory: bool) -> void:
	_finished = true
	var result_text: String = "VITÓRIA" if victory else "DERROTA"
	print("Fim da missão: %s (turno %d)" % [result_text, _turn_manager.turn_number])
	_show_banner(result_text, Color(0.25, 0.9, 0.35) if victory else Color(0.95, 0.2, 0.2))
	get_tree().paused = true


# Letreiro criado em código: texto grande e centralizado, com a dica de reinício embaixo.
func _show_banner(result_text: String, color: Color) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "MissionBanner"
	layer.layer = overlay_layer
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)

	var title: Label = Label.new()
	title.text = result_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", color)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 16)
	box.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Pressione R para reiniciar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 32)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 8)
	box.add_child(hint)

	add_child(layer)
