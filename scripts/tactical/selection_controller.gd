class_name SelectionController
extends Node3D
## Seleção de soldados com o clique esquerdo do mouse.
## A unidade clicada é identificada por um raio físico a partir da câmera
## (apenas na camada de colisão das unidades), nunca pelo plano do chão.

## Emitido quando um soldado é selecionado.
signal unit_selected(unit: Unit)
## Emitido quando a seleção é limpa.
signal selection_cleared
## Emitido quando o clique esquerdo cai no chão (fora de qualquer unidade).
## A célula pode estar fora da grade; quem recebe decide o que fazer (inclusive limpar a seleção).
signal cell_clicked(cell: Vector2i)

## Caminho até a câmera da fase.
@export var camera_path: NodePath = ^"../Camera"
## Caminho até o GridManager (posição e tamanho do marcador).
@export var grid_manager_path: NodePath = ^"../GridManager"
## Camada de colisão das unidades (camada 2).
@export_flags_3d_physics var unit_collision_mask: int = 2
## Comprimento do raio de seleção, em metros.
@export var ray_length: float = 200.0
## Cor do marcador de seleção (amarelo semitransparente).
@export var marker_color: Color = Color(1.0, 0.9, 0.1, 0.5)
## Altura do marcador acima da superfície do chão, em metros.
@export var marker_height: float = 0.02

## Soldado atualmente selecionado (null quando não há seleção).
var selected_unit: Unit = null

var _camera: Camera3D
var _grid_manager: GridManager
var _marker: MeshInstance3D


func _ready() -> void:
	_camera = get_node(camera_path) as Camera3D
	_grid_manager = get_node(grid_manager_path) as GridManager
	assert(_camera != null, "SelectionController: camera_path não aponta para uma Camera3D.")
	assert(_grid_manager != null, "SelectionController: grid_manager_path não aponta para um GridManager.")
	_build_marker()


func _unhandled_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var unit: Unit = _pick_unit(mouse_event.position)
	if unit == null:
		_handle_floor_click(mouse_event.position)
	elif unit.team == Unit.Team.SQUAD:
		select_unit(unit)
	else:
		print("Inimigo clicado (não selecionável): %s" % unit.unit_name)


## Seleciona o soldado e move o marcador para a célula dele.
func select_unit(unit: Unit) -> void:
	selected_unit = unit
	_marker.global_position = _grid_manager.cell_to_world(unit.cell) + Vector3(0.0, marker_height, 0.0)
	_marker.visible = true
	print("Selecionado: %s (%d, %d)" % [unit.unit_name, unit.cell.x, unit.cell.y])
	unit_selected.emit(unit)


## Limpa a seleção e esconde o marcador.
func clear_selection() -> void:
	selected_unit = null
	_marker.visible = false
	print("Seleção limpa")
	selection_cleared.emit()


## Esconde o marcador de seleção sem limpar a seleção (por exemplo, durante um movimento).
func hide_marker() -> void:
	_marker.visible = false


## Dispara um raio físico da câmera pelo ponto da tela e devolve a unidade atingida (ou null).
func _pick_unit(screen_pos: Vector2) -> Unit:
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var end: Vector3 = origin + _camera.project_ray_normal(screen_pos) * ray_length
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end, unit_collision_mask)
	query.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Node = hit["collider"] as Node
	return collider.get_parent() as Unit


## Clique que não acertou unidade: converte o ponto do chão (plano y = 0) em célula e avisa por sinal.
## Se o raio não encontra o plano, trata como clique fora de tudo e limpa a seleção.
func _handle_floor_click(screen_pos: Vector2) -> void:
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	var floor_point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if floor_point == null:
		clear_selection()
		return
	cell_clicked.emit(_grid_manager.world_to_cell(floor_point as Vector3))


func _build_marker() -> void:
	var cell_size: float = _grid_manager.grid_floor.cell_size

	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(cell_size, cell_size)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = marker_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_marker = MeshInstance3D.new()
	_marker.name = "SelectionMarker"
	_marker.mesh = mesh
	_marker.material_override = material
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.visible = false
	add_child(_marker)
