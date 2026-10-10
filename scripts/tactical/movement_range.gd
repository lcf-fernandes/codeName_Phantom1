class_name MovementRange
extends Node3D
## Calcula e mostra as células que o soldado selecionado consegue alcançar.
## Busca em largura nas 4 direções, custo 1 por passo, até move_range passos.
## Células ocupadas por qualquer unidade (grupo "units") bloqueiam a passagem.

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (origem dos sinais de seleção).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o GridManager.
@export var grid_manager_path: NodePath = ^"../GridManager"
## Caminho até o CoverMap (células com cobertura bloqueiam o movimento).
@export var cover_map_path: NodePath = ^"../CoverMap"
## Lado de cada quadrado de alcance, em metros.
@export var tile_size: float = 1.8
## Altura dos quadrados acima da superfície do chão, em metros.
@export var tile_height: float = 0.015
## Cor dos quadrados de alcance (azul-claro semitransparente).
@export var tile_color: Color = Color(0.45, 0.75, 1.0, 0.45)

var _grid_manager: GridManager
var _cover_map: CoverMap
var _tile_mesh: PlaneMesh
var _tile_material: StandardMaterial3D
var _tiles: Array[MeshInstance3D] = []


func _ready() -> void:
	_grid_manager = get_node(grid_manager_path) as GridManager
	_cover_map = get_node(cover_map_path) as CoverMap
	var selection: SelectionController = get_node(selection_controller_path) as SelectionController
	assert(_grid_manager != null, "MovementRange: grid_manager_path não aponta para um GridManager.")
	assert(_cover_map != null, "MovementRange: cover_map_path não aponta para um CoverMap.")
	assert(selection != null, "MovementRange: selection_controller_path não aponta para um SelectionController.")

	_tile_mesh = PlaneMesh.new()
	_tile_mesh.size = Vector2(tile_size, tile_size)

	_tile_material = StandardMaterial3D.new()
	_tile_material.albedo_color = tile_color
	_tile_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tile_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tile_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	selection.unit_selected.connect(_on_unit_selected)
	selection.selection_cleared.connect(_on_selection_cleared)


## Células alcançáveis pela unidade, com o custo (passos) de cada uma.
## A célula de origem não entra no resultado.
func compute_reachable(unit: Unit) -> Dictionary[Vector2i, int]:
	var parents: Dictionary[Vector2i, Vector2i] = {}
	return _search(unit, parents)


## Caminho mais curto até a célula, da primeira célula depois da origem até o destino.
## Devolve uma lista vazia se a célula não for alcançável. O tamanho do caminho é igual ao custo.
func get_move_path(unit: Unit, cell: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var parents: Dictionary[Vector2i, Vector2i] = {}
	var reachable: Dictionary[Vector2i, int] = _search(unit, parents)
	if not reachable.has(cell):
		return path

	var current: Vector2i = cell
	while current != unit.cell:
		path.push_front(current)
		current = parents[current]
	return path


## Esconde os quadrados de alcance.
func hide_range() -> void:
	_show_tiles([])


## Busca em largura a partir da célula da unidade. Devolve célula -> custo e preenche
## parents com a célula de onde cada célula foi alcançada (para reconstruir caminhos).
func _search(unit: Unit, parents: Dictionary[Vector2i, Vector2i]) -> Dictionary[Vector2i, int]:
	var reachable: Dictionary[Vector2i, int] = {}
	var occupied: Dictionary[Vector2i, bool] = _get_occupied_cells()
	var costs: Dictionary[Vector2i, int] = {unit.cell: 0}
	var queue: Array[Vector2i] = [unit.cell]
	var head: int = 0

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var cost: int = costs[current]
		if cost >= unit.move_range:
			continue
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = current + direction
			if costs.has(next) or occupied.has(next) or _cover_map.is_blocked(next) or not _grid_manager.is_inside(next):
				continue
			costs[next] = cost + 1
			reachable[next] = cost + 1
			parents[next] = current
			queue.append(next)

	return reachable


func _get_occupied_cells() -> Dictionary[Vector2i, bool]:
	var occupied: Dictionary[Vector2i, bool] = {}
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var other: Unit = node as Unit
		if other != null:
			occupied[other.cell] = true
	return occupied


func _on_unit_selected(unit: Unit) -> void:
	# Sem PA: não há alcance a mostrar.
	if unit.action_points <= 0:
		_show_tiles([])
		print("Alcance de %s: 0 células (sem PA)" % unit.unit_name)
		return

	var reachable: Dictionary[Vector2i, int] = compute_reachable(unit)

	# Ordem: menor custo primeiro; empate por x e depois por y.
	var cells: Array[Vector2i] = []
	cells.assign(reachable.keys())
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if reachable[a] != reachable[b]:
			return reachable[a] < reachable[b]
		if a.x != b.x:
			return a.x < b.x
		return a.y < b.y
	)

	_show_tiles(cells)

	var parts: PackedStringArray = PackedStringArray()
	for c: Vector2i in cells:
		parts.append("(%d, %d):%d" % [c.x, c.y, reachable[c]])
	print("Alcance de %s: %d células" % [unit.unit_name, cells.size()])
	print("  Células (x, y):custo -> %s" % ", ".join(parts))


func _on_selection_cleared() -> void:
	_show_tiles([])


## Mostra um quadrado em cada célula da lista e esconde os que sobrarem.
func _show_tiles(cells: Array[Vector2i]) -> void:
	while _tiles.size() < cells.size():
		var tile: MeshInstance3D = MeshInstance3D.new()
		tile.mesh = _tile_mesh
		tile.material_override = _tile_material
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tile)
		_tiles.append(tile)

	for i: int in _tiles.size():
		var tile: MeshInstance3D = _tiles[i]
		if i < cells.size():
			tile.global_position = _grid_manager.cell_to_world(cells[i]) + Vector3(0.0, tile_height, 0.0)
			tile.visible = true
		else:
			tile.visible = false
