extends Node

@export var show_on_start: bool = true
@export var auto_hide_seconds: float = 10.0
@export var toggle_key: Key = KEY_H

const ENTRIES: Array = [
    ["Botão esquerdo", "Selecionar, mover e atacar"],
    ["Botão direito / Esc", "Cancelar a mira"],
    ["1 / 2 / 3", "Atacar / Defender / Vigilância"],
    ["Tab / Shift+Tab", "Próximo / anterior soldado"],
    ["Enter", "Encerrar o turno"],
    ["W A S D / setas", "Mover a câmera"],
    ["Espaço", "Centralizar no soldado"],
    ["C", "Mostrar a célula sob o mouse"],
    ["H", "Mostrar ou esconder esta ajuda"],
    ["R", "Reiniciar (depois do fim da missão)"],
]

var _layer: CanvasLayer
var _panel: PanelContainer
var _touched: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()
    _panel.visible = show_on_start
    call_deferred("_center_panel")
    if show_on_start:
        get_tree().create_timer(auto_hide_seconds).timeout.connect(_on_auto_hide)


func _make_label(text: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    return label


func _build_ui() -> void:
    _layer = CanvasLayer.new()
    _layer.layer = 7
    add_child(_layer)

    var hint := _make_label("[H] Ajuda", 16, Color(1, 1, 1, 0.85))
    hint.add_theme_constant_override("outline_size", 6)
    hint.add_theme_color_override("font_outline_color", Color.BLACK)
    _layer.add_child(hint)
    hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)

    _panel = PanelContainer.new()
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.03, 0.04, 0.08, 0.88)
    style.set_content_margin_all(20)
    style.set_corner_radius_all(8)
    _panel.add_theme_stylebox_override("panel", style)

    var box := VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_theme_constant_override("separation", 10)
    box.add_child(_make_label("TECLAS", 24, Color.WHITE))

    var grid := GridContainer.new()
    grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 28)
    grid.add_theme_constant_override("v_separation", 6)
    for entry in ENTRIES:
        grid.add_child(_make_label(entry[0], 18, Color(1.0, 0.85, 0.3)))
        grid.add_child(_make_label(entry[1], 18, Color.WHITE))
    box.add_child(grid)

    _panel.add_child(box)
    _layer.add_child(_panel)


func _center_panel() -> void:
    _panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _unhandled_input(event: InputEvent) -> void:
    var key := event as InputEventKey
    if key == null or not key.pressed or key.echo or key.keycode != toggle_key:
        return
    _touched = true
    _panel.visible = not _panel.visible
    get_viewport().set_input_as_handled()


func _on_auto_hide() -> void:
    if not _touched:
        _panel.visible = false
