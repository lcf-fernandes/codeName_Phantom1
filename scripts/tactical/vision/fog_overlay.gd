class_name FogOverlay
extends Node3D
## Fog of war, parte 2: escurece o chão das células que o esquadrão não enxerga.
## Um quadrado semitransparente por célula da grade, mostrado quando a célula não é visível.
## Só visual: sem colisores, e nada aqui captura o mouse.

## Caminho até o VisionSystem (quais células estão visíveis).
@export var vision_system_path: NodePath = ^"../VisionSystem"
## Caminho até o GridManager (tamanho da grade e posição das células).
@export var grid_manager_path: NodePath = ^"../GridManager"
## Cor dos quadrados de névoa.
@export var fog_color: Color = Color(0.02, 0.03, 0.07, 0.6)
## Altura dos quadrados acima da superfície do chão, em metros.
@export var overlay_height: float = 0.01
## Quando falso, a névoa do chão fica toda escondida.
@export var overlay_enabled: bool = true

var _vision: VisionSystem
var _grid_manager: GridManager
var _tiles: Dictionary[Vector2i, MeshInstance3D] = {}


func _ready() -> void:
	_vision = get_node(vision_system_path) as VisionSystem
	_grid_manager = get_node(grid_manager_path) as GridManager
	assert(_vision != null, "FogOverlay: vision_system_path não aponta para um VisionSystem.")
	assert(_grid_manager != null, "FogOverlay: grid_manager_path não aponta para um GridManager.")
	# Depois de o GridManager ter encontrado o chão.
	_build_tiles.call_deferred()


# Cria um quadrado por célula, todos com o mesmo mesh e o mesmo material.
func _build_tiles() -> void:
	var cell_size: float = _grid_manager.grid_floor.cell_size
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(cell_size - 0.02, cell_size - 0.02)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = fog_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for x: int in _grid_manager.grid_floor.grid_width:
		for y: int in _grid_manager.grid_floor.grid_depth:
			var cell: Vector2i = Vector2i(x, y)
			var tile: MeshInstance3D = MeshInstance3D.new()
			tile.name = "Fog_%d_%d" % [x, y]
			tile.mesh = mesh
			tile.material_override = material
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(tile)
			tile.global_position = _grid_manager.cell_to_world(cell) + Vector3(0.0, overlay_height, 0.0)
			_tiles[cell] = tile

	_vision.visibility_changed.connect(_refresh)
	_refresh()


# Mostra a névoa só nas células que o esquadrão não enxerga.
func _refresh() -> void:
	for cell: Vector2i in _tiles.keys():
		_tiles[cell].visible = overlay_enabled and not _vision.is_cell_visible(cell)
