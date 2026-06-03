class_name LevelCollision
extends SGFixedNode2D

## The precision used in the pixel-perfect collision. Higher numbers = less collision but better
## performance.
@export_range(1.0, 5.0) var _precision: float = 1.5

## The number of segments that the level geometry is divided into when generated. Might need to
## be raised for particularly complex levels.
@export_range(1, 4) var _segments: int = 2

var _phys_serv_rids: Array[RID] = []


func _notification(what: int) -> void:
	# Delete everything from the physics server when the node is freed
	if what == NOTIFICATION_PREDELETE:
		for rid: RID in _phys_serv_rids:
			SGPhysics2DServer.free_rid(rid)


func generate_collision(wall_tex: Texture2D):
	# Generate SGCollisionPolygons and then convert them to physics server objects.
	var collision_polys := GeomUtil.create_sgpolygons_from_texture_hollow(
		wall_tex, _precision, _segments
	)
	for collision_poly: SGCollisionPolygon2D in collision_polys:
		# Even though we're ultimately not going to use the collision polygon node, we
		# still parent them to the tree so we can use their global transform information
		# to position the physics server objects. We'll delete them when finished.
		add_child(collision_poly)
		collision_poly.force_update_transform()

		# Convert the polygon's shape into a physics server shape
		var shape := SGPhysics2DServer.shape_create(SGPhysics2DServer.SHAPE_POLYGON)
		SGPhysics2DServer.polygon_set_points(shape, collision_poly.fixed_polygon)
		# print(collision_poly.fixed_polygon)
		# SGPhysics2DServer.shape_set_transform(shape, collision_poly.fixed_transform)

		# Create a collision object and add the shape to it
		var collision_object := SGPhysics2DServer.collision_object_create(
			SGPhysics2DServer.OBJECT_BODY, SGPhysics2DServer.BODY_STATIC
		)
		SGPhysics2DServer.collision_object_add_shape(collision_object, shape)

		SGPhysics2DServer.collision_object_set_transform(
			collision_object, collision_poly.fixed_transform
		)

		# Layer 2 = the walls layer
		SGPhysics2DServer.collision_object_set_collision_layer(collision_object, 2)

		# You have to give each object a unique ID for the determinism to work. I'm using
		# the collision poly node's name since Godot should have given it a unique name
		# automatically.
		var data := "LevelWall_" + collision_poly.name as String
		SGPhysics2DServer.collision_object_set_data(collision_object, data)

		# Save this object so we can remove it later
		_phys_serv_rids.push_back(collision_object)

		SGPhysics2DServer.world_add_collision_object(
			SGPhysics2DServer.get_default_world(), collision_object
		)

		# Free the node now that we're done with it
		collision_poly.queue_free()
