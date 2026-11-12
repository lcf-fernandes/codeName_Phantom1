extends Node

@export var turn_manager_path: NodePath = ^"../TurnManager"
@export var attack_controller_path: NodePath = ^"../AttackController"
@export var show_delay: float = 0.8
@export var vertical_position: float = 0.62

var _layer: CanvasLayer
var _panel: PanelContainer
var _stats_label: Label

var _started_msec: int = 0
var _total_enemies: int = 0
var _total_soldiers: int = 0
var _enemies_killed: int = 0
var _soldiers_lost: int = 0
var _shots: int = 0
var _last_turn: int = 1
var _shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started_msec = Time.get_ticks_msec()
	var turn_manager: TurnManager = get_node_or_null(turn_manager_path) as TurnManager
	if turn_manager != null:
		turn_manager.turn_started.connect(_on_turn_started)
	var attack: Node = get_node_or_null(attack_controller_path)
	if attack != null and attack.has_signal("attack_started"):
		attack.connect("attack_started", _on_attack_started)
	_build_ui()
	call_deferred("_connect_units")


func _connect_units() -> void:
	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit: Unit = node as Unit
		if unit == null:
			continue
		if unit.team == Unit.Team.ENEMY:
			_total_enemies += 1
		else:
			_total_soldiers += 1
		unit.died.connect(_on_unit_died)


func _on_unit_died(unit: Unit) -> void:
	if unit.team == Unit.Team.ENEMY:
		_enemies_killed += 1
	else:
		_soldiers_lost += 1


func _on_turn_started(turn_number: int, _side: int) -> void:
	_last_turn = turn_number


func _on_attack_started(attacker: Unit, _defender: Unit) -> void:
	if attacker != null and attacker.team == Unit.Team.SQUAD:
		_shots += 1


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 11
	add_child(_layer)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.08, 0.9)
	style.set_content_margin_all(24)
	style.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "RESULTADO"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	_stats_label = Label.new()
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_label.add_theme_font_size_override("font_size", 20)
	box.add_child(_stats_label)

	_panel.add_child(box)
	_layer.add_child(_panel)
	_panel.modulate.a = 0.0
	_panel.visible = false


func _process(_delta: float) -> void:
	if _shown or not get_tree().paused:
		return
	_shown = true
	_show_results()


func _show_results() -> void:
	var seconds: int = int((Time.get_ticks_msec() - _started_msec) / 1000.0)
	var minutes: int = floori(seconds / 60.0)
	_stats_label.text = "Turnos: %d\nInimigos eliminados: %d de %d\nSoldados perdidos: %d de %d\nDisparos: %d\nTempo: %02d:%02d" % [
		_last_turn, _enemies_killed, _total_enemies, _soldiers_lost, _total_soldiers,
		_shots, minutes, seconds % 60
	]
	await get_tree().create_timer(show_delay).timeout
	_panel.visible = true
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.position.y = get_viewport().get_visible_rect().size.y * vertical_position
	var tween: Tween = _panel.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.4)
