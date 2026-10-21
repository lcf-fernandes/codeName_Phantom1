class_name CellReadout
extends Node
## Mostra, no canto superior direito, a célula da grade sob o mouse.
## O raio da câmera até o mouse é intersectado com o plano do chão (y = 0) e convertido pelo
## GridManager. A tecla C liga e desliga o texto.

## Caminho até a câmera da fase.
@export var camera_path: NodePath = ^"../Camera"
## Caminho até o GridManager.
@export var grid_manager_path: NodePath = ^"../GridManager"
## Tamanho da fonte do texto.
@export var font_size: int = 22
## Distância do texto até as bordas da tela, em pixels.
@export var screen_margin: int = 16

var _camera: Camera3D
var _grid_manager: GridManager
var _layer: CanvasLayer
var _label: Label


func _ready() -> void:
	_camera = get_node(camera_path) as Camera3D
	_grid_manager = get_node(grid_manager_path) as GridManager
	assert(_camera != null, "CellReadout: camera_path não aponta para uma Camera3D.")
	assert(_grid_manager != null, "CellReadout: grid_manager_path não aponta para um GridManager.")
	_build_ui()


func _process(_delta: float) -> void:
	if not _label.visible:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = _camera.project_ray_normal(mouse_pos)
	var floor_point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)

	var text: String = "Célula: fora da grade"
	if floor_point != null:
		var cell: Vector2i = _grid_manager.world_to_cell(floor_point as Vector3)
		if _grid_manager.is_inside(cell):
			text = "Célula: (%d, %d)" % [cell.x, cell.y]
	if _label.text != text:
		_label.text = text


# A tecla C liga e desliga o texto.
func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_C:
		_label.visible = not _label.visible


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "CellReadoutLayer"
	_layer.layer = 6
	add_child(_layer)

	_label = Label.new()
	_label.name = "CellLabel"
	_label.text = "Célula: fora da grade"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ancorado no canto superior direito; cresce para a esquerda e para baixo.
	_label.anchor_left = 1.0
	_label.anchor_right = 1.0
	_label.anchor_top = 0.0
	_label.anchor_bottom = 0.0
	_label.offset_right = -screen_margin
	_label.offset_top = screen_margin
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.grow_vertical = Control.GROW_DIRECTION_END

	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)

	# Fundo escuro semitransparente.
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.06, 0.09, 0.7)
	background.content_margin_left = 12.0
	background.content_margin_right = 12.0
	background.content_margin_top = 6.0
	background.content_margin_bottom = 6.0
	_label.add_theme_stylebox_override("normal", background)

	_layer.add_child(_label)
