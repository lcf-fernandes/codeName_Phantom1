class_name SquadSpawner
extends Node3D
## Cria as unidades do esquadrão ao iniciar a cena, uma em cada célula da lista.

const UNIT_SCENE: PackedScene = preload("res://scenes/units/unit.tscn")

## Caminho até o GridManager usado para posicionar as unidades.
@export var grid_manager_path: NodePath = ^"../GridManager"
## Células iniciais do esquadrão. A quantidade de células define quantas unidades são criadas.
@export var spawn_cells: Array[Vector2i] = [
	Vector2i(4, 0),
	Vector2i(5, 0),
	Vector2i(6, 0),
	Vector2i(7, 0),
]
## Prefixo do nome; a unidade recebe o prefixo seguido do número (Soldado 1, Soldado 2...).
@export var name_prefix: String = "Soldado"
## Cor do corpo das unidades do esquadrão.
@export var squad_color: Color = Color(0.2, 0.4, 0.9)


func _ready() -> void:
	var grid_manager: GridManager = get_node(grid_manager_path) as GridManager
	assert(grid_manager != null, "SquadSpawner: grid_manager_path não aponta para um GridManager.")

	for i: int in spawn_cells.size():
		var unit: Unit = UNIT_SCENE.instantiate() as Unit
		unit.unit_name = "%s %d" % [name_prefix, i + 1]
		unit.name = unit.unit_name
		unit.body_color = squad_color
		add_child(unit)
		unit.place_on_cell(grid_manager, spawn_cells[i])
		print("[Esquadrão] %s | célula %s | mundo %s" % [unit.unit_name, unit.cell, unit.global_position])
