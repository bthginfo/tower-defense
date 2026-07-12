extends Node3D

const TILE:PackedScene=preload("res://assets/third_party/kenney/tower_defense_3d/tile.glb")
const TREE:PackedScene=preload("res://assets/third_party/kenney/tower_defense_3d/tile-tree.glb")
const TREE_DOUBLE:PackedScene=preload("res://assets/third_party/kenney/tower_defense_3d/tile-tree-double.glb")
const ROCK:PackedScene=preload("res://assets/third_party/kenney/tower_defense_3d/tile-rock.glb")
const CRYSTAL:PackedScene=preload("res://assets/third_party/kenney/tower_defense_3d/tile-crystal.glb")

func _ready() -> void:
	for z in range(-4,5):
		for x in range(-7,8):
			var scene:=TILE
			if (x*17+z*31)%19==0: scene=TREE
			elif (x*11+z*23)%29==0: scene=TREE_DOUBLE
			elif (x*7+z*13)%31==0: scene=ROCK
			elif (x*5+z*37)%43==0: scene=CRYSTAL
			var tile:=scene.instantiate()
			tile.position=Vector3(x,0,z)
			add_child(tile)
	$Camera3D.look_at(Vector3(0,0,-0.4),Vector3.UP)

