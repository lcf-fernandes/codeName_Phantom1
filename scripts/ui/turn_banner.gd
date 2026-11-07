extends Node

@export var turn_manager_path: NodePath = ^"../TurnManager"
@export var player_color: Color = Color(0.35, 0.65, 1.0)
@export var enemy_color: Color = Color(1.0, 0.35, 0.3)
@export var hold_time: float = 1.0
@export var vertical_position: float = 0.28

var _turn_manager: TurnManager
var _layer: CanvasLayer
var _panel: PanelContainer
var _label: Label
var _tween: Tween
var _shown_any: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_turn_manager = get_node_or_null(turn_manager_path) as TurnManager
	assert(_turn_manager != null, "TurnBanner: TurnManager não encontrado")
	_build_ui()
	_turn_manager.turn_started.connect(_on_turn_started)
	get_tree().create_timer(0.5).timeout.connect(_on_start_timeout)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 6
	add_child(_layer)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.08, 0.75)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_constant_override("outline_size", 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_panel.add_child(_label)
	_layer.add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.modulate.a = 0.0
	_panel.visible = false


func _show_banner(text: String, color: Color) -> void:
	if get_tree().paused:
		return
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_panel.position.y = get_viewport().get_visible_rect().size.y * vertical_position
	_panel.visible = true
	if _tween != null:
		_tween.kill()
	_tween = _panel.create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.2).from(0.0)
	_tween.tween_interval(hold_time)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func() -> void: _panel.visible = false)


func _on_turn_started(turn_number: int, side: int) -> void:
	_shown_any = true
	if side == TurnManager.TurnSide.PLAYER:
		_show_banner("TURNO %d · JOGADOR" % turn_number, player_color)
	else:
		_show_banner("TURNO %d · INIMIGOS" % turn_number, enemy_color)


func _on_start_timeout() -> void:
	if not _shown_any:
		_show_banner("TURNO 1 · JOGADOR", player_color)
