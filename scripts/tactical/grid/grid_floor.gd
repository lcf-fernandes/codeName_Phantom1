class_name GridFloor
extends Node3D
## Gera o chão em grade (tabuleiro) da fase de teste.
## A grade fica centrada na origem deste nó e a face superior das células fica em y = 0.

## Número de células no eixo X.
@export var grid_width: int = 12
## Número de células no eixo Z.
@export var grid_depth: int = 12
## Lado de cada célula, em metros.
@export var cell_size: float = 2.0
## Espaçamento visível entre células vizinhas, em metros.
@export var cell_gap: float = 0.1
## Espessura (altura) de cada bloco, em metros.
@export var cell_height: float = 0.2
## Tom claro do tabuleiro.
@export var color_light: Color = Color(0.62, 0.62, 0.62)
## Tom escuro do tabuleiro.
@export var color_dark: Color = Color(0.38, 0.38, 0.38)


func _ready() -> void:
	_build_grid()


func _build_grid() -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(cell_size - cell_gap, cell_height, cell_size - cell_gap)

	var material_light: StandardMaterial3D = _make_material(color_light)
	var material_dark: StandardMaterial3D = _make_material(color_dark)

	var origin: Vector3 = get_grid_origin()

	for x: int in grid_width:
		for z: int in grid_depth:
			var cell: MeshInstance3D = MeshInstance3D.new()
			cell.name = "Cell_%d_%d" % [x, z]
			cell.mesh = mesh
			cell.material_override = material_light if (x + z) % 2 == 0 else material_dark
			cell.position = origin + Vector3(x * cell_size, 0.0, z * cell_size)
			add_child(cell)


## Posição local do centro da célula (0, 0), a meia altura do bloco.
## A grade fica centrada na origem do nó e a face superior das células fica em y = 0.
func get_grid_origin() -> Vector3:
	return Vector3(
		-(grid_width - 1) * cell_size * 0.5,
		-cell_height * 0.5,
		-(grid_depth - 1) * cell_size * 0.5
	)


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
