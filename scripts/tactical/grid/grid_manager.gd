class_name GridManager
extends Node3D
## Converte entre coordenadas de célula da grade e posições no mundo 3D.
## O tamanho da grade, o tamanho da célula e a origem vêm do GridFloor (fonte única).
## Vector2i(x, y) da célula corresponde aos eixos X e Z do mundo.

## Caminho até o chão que define a grade.
@export var grid_floor_path: NodePath = ^"../GridFloor"
## Quando verdadeiro, roda um teste de conversão ao iniciar e imprime no painel de Saída.
@export var debug_test: bool = true

var grid_floor: GridFloor


func _ready() -> void:
	grid_floor = get_node(grid_floor_path) as GridFloor
	assert(grid_floor != null, "GridManager: grid_floor_path não aponta para um GridFloor.")
	if debug_test:
		_run_debug_test()


## Centro da célula, na altura da face superior do chão.
func cell_to_world(cell: Vector2i) -> Vector3:
	var origin: Vector3 = grid_floor.get_grid_origin()
	var local_pos: Vector3 = Vector3(
		origin.x + cell.x * grid_floor.cell_size,
		origin.y + grid_floor.cell_height * 0.5,
		origin.z + cell.y * grid_floor.cell_size
	)
	return grid_floor.to_global(local_pos)


## Célula que contém a posição (pode estar fora da grade; use is_inside para checar).
func world_to_cell(pos: Vector3) -> Vector2i:
	var origin: Vector3 = grid_floor.get_grid_origin()
	var local_pos: Vector3 = grid_floor.to_local(pos)
	return Vector2i(
		floori((local_pos.x - origin.x) / grid_floor.cell_size + 0.5),
		floori((local_pos.z - origin.z) / grid_floor.cell_size + 0.5)
	)


## Diz se a célula está dentro da grade.
func is_inside(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < grid_floor.grid_width
		and cell.y >= 0
		and cell.y < grid_floor.grid_depth
	)


func _run_debug_test() -> void:
	var last_x: int = grid_floor.grid_width - 1
	var last_y: int = grid_floor.grid_depth - 1

	print("[GridManager] cell_to_world nos cantos:")
	var corners: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(last_x, 0),
		Vector2i(0, last_y),
		Vector2i(last_x, last_y),
	]
	for corner: Vector2i in corners:
		print("  ", corner, " -> ", cell_to_world(corner))

	var total: int = 0
	var failures: int = 0
	for x: int in grid_floor.grid_width:
		for y: int in grid_floor.grid_depth:
			var cell: Vector2i = Vector2i(x, y)
			total += 1
			if world_to_cell(cell_to_world(cell)) != cell:
				failures += 1
	print("[GridManager] ida e volta world_to_cell(cell_to_world(c)): %d células, %d falhas" % [total, failures])

	print("[GridManager] is_inside:")
	var samples: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(grid_floor.grid_width, 0),
		Vector2i(5, 5),
	]
	for sample: Vector2i in samples:
		print("  ", sample, " -> ", is_inside(sample))
