class_name CoverMap
extends Node3D
## Coberturas como dados da grade (uma única fonte: as duas listas de células).
## Cada célula da lista ganha uma forma 3D simples e passa a bloquear o movimento.
## Ainda sem efeito em combate.

## Tipo de cobertura de uma célula.
enum CoverType { NONE, LOW, HIGH }

const UNITS_GROUP: StringName = &"units"

## Caminho até o GridManager.
@export var grid_manager_path: NodePath = ^"../GridManager"
## Células com cobertura baixa.
@export var low_cover_cells: Array[Vector2i] = [Vector2i(3, 5), Vector2i(4, 5), Vector2i(7, 6)]
## Células com cobertura alta.
@export var high_cover_cells: Array[Vector2i] = [Vector2i(8, 5), Vector2i(2, 7)]
## Lado da base das formas, em metros.
@export var footprint: float = 1.8
## Altura da cobertura baixa, em metros.
@export var low_height: float = 1.0
## Altura da cobertura alta, em metros.
@export var high_height: float = 2.0
## Cor da cobertura baixa (marrom-acinzentado claro).
@export var low_color: Color = Color(0.62, 0.55, 0.47)
## Cor da cobertura alta (cinza-escuro).
@export var high_color: Color = Color(0.25, 0.26, 0.28)

var _grid_manager: GridManager


func _ready() -> void:
	_grid_manager = get_node(grid_manager_path) as GridManager
	assert(_grid_manager != null, "CoverMap: grid_manager_path não aponta para um GridManager.")

	_validate()
	print("[Coberturas] baixas: %s | altas: %s" % [_cells_text(low_cover_cells), _cells_text(high_cover_cells)])
	for cell: Vector2i in low_cover_cells:
		_build_shape(cell, low_height, low_color, "Baixa")
	for cell: Vector2i in high_cover_cells:
		_build_shape(cell, high_height, high_color, "Alta")


## Tipo de cobertura da célula (alta tem prioridade se a célula estiver nas duas listas).
func get_cover(cell: Vector2i) -> CoverType:
	if high_cover_cells.has(cell):
		return CoverType.HIGH
	if low_cover_cells.has(cell):
		return CoverType.LOW
	return CoverType.NONE


## Verdadeiro para qualquer célula com cobertura.
func is_blocked(cell: Vector2i) -> bool:
	return get_cover(cell) != CoverType.NONE


# Avisa (push_warning e print) sobre células fora da grade, repetidas ou em linhas de início.
func _validate() -> void:
	var last_row: int = _grid_manager.grid_floor.grid_depth - 1
	var unit_cells: Dictionary[Vector2i, bool] = {}
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null:
			unit_cells[unit.cell] = true

	var counts: Dictionary[Vector2i, int] = {}
	var all_cells: Array[Vector2i] = []
	all_cells.append_array(low_cover_cells)
	all_cells.append_array(high_cover_cells)
	for cell: Vector2i in all_cells:
		counts[cell] = counts.get(cell, 0) + 1

	var reported: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in all_cells:
		if not _grid_manager.is_inside(cell):
			_warn("célula %s está fora da grade" % cell)
		if counts[cell] > 1 and not reported.has(cell):
			reported[cell] = true
			_warn("célula %s aparece %d vezes nas listas de cobertura" % [cell, counts[cell]])
		if cell.y == 0 or cell.y == last_row:
			_warn("célula %s está em uma linha de início de unidades (0 ou %d)" % [cell, last_row])
		if unit_cells.has(cell):
			_warn("célula %s coincide com a célula de uma unidade" % cell)


func _build_shape(cell: Vector2i, height: float, color: Color, label: String) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(footprint, height, footprint)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9

	var shape: MeshInstance3D = MeshInstance3D.new()
	shape.name = "%s_%d_%d" % [label, cell.x, cell.y]
	shape.mesh = mesh
	shape.material_override = material
	add_child(shape)
	# Apoiada no chão: o centro vertical fica em metade da altura.
	shape.global_position = _grid_manager.cell_to_world(cell) + Vector3(0.0, height * 0.5, 0.0)
	print("  %s %s -> centro global %s" % [label, cell, shape.global_position])


func _warn(message: String) -> void:
	push_warning("[Coberturas] " + message)
	print("[Coberturas] AVISO: " + message)


func _cells_text(cells: Array[Vector2i]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for cell: Vector2i in cells:
		parts.append("(%d, %d)" % [cell.x, cell.y])
	return ", ".join(parts)
