class_name EnemySpawner
extends Node3D
## Cria os inimigos ao iniciar a cena, um em cada célula da lista.

const ENEMY_SCENE: PackedScene = preload("res://scenes/units/enemy_unit.tscn")

## Caminho até o GridManager usado para posicionar as unidades.
@export var grid_manager_path: NodePath = ^"../GridManager"
## Células iniciais dos inimigos. A quantidade de células define quantos inimigos são criados.
@export var spawn_cells: Array[Vector2i] = [
	Vector2i(4, 11),
	Vector2i(6, 11),
	Vector2i(8, 11),
]
## Prefixo do nome; o inimigo recebe o prefixo seguido do número (Inimigo 1, Inimigo 2...).
@export var name_prefix: String = "Inimigo"
## Grupo (cluster_id) de cada inimigo, na ordem de spawn_cells; sem valor para o índice, vale 0.
@export var cluster_ids: Array[int] = []
## Estado de alerta com que os inimigos nascem.
@export var start_alerted: bool = true


func _ready() -> void:
	var grid_manager: GridManager = get_node(grid_manager_path) as GridManager
	assert(grid_manager != null, "EnemySpawner: grid_manager_path não aponta para um GridManager.")

	for i: int in spawn_cells.size():
		var unit: Unit = ENEMY_SCENE.instantiate() as Unit
		unit.unit_name = "%s %d" % [name_prefix, i + 1]
		unit.name = unit.unit_name
		unit.cluster_id = cluster_ids[i] if i < cluster_ids.size() else 0
		unit.alerted = start_alerted
		add_child(unit)
		unit.place_on_cell(grid_manager, spawn_cells[i])
		var body: Node3D = unit.get_node("Body") as Node3D
		print("[Inimigos] %s | célula %s | mundo (raiz) %s | malha global y = %s | grupo %d" % [
			unit.unit_name, unit.cell, unit.global_position, body.global_position.y, unit.cluster_id
		])
