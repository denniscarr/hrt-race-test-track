class_name GeomUtil
extends Object


## Generates and returns an array of collision polygon nodes which match the shape of [texture]
static func create_polygons_from_texture(
		texture: Texture2D,
		precision: float = 2.0,
) -> Array[CollisionPolygon2D]:
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())

	var rect := Rect2i(0, 0, texture.get_width(), texture.get_height())
	var bitmap_polygons := bitmap.opaque_to_polygons(rect, precision)

	var collision_polygons: Array[CollisionPolygon2D] = []
	for i: int in range(bitmap_polygons.size()):
		var new_collision_polygon := CollisionPolygon2D.new()
		new_collision_polygon.polygon = bitmap_polygons[i]
		new_collision_polygon.position.x -= ceili(texture.get_width() / 2.0)
		new_collision_polygon.position.y -= ceili(texture.get_height() / 2.0)
		collision_polygons.push_back(new_collision_polygon)

	return collision_polygons


## Generates and returns an array of collision polygon nodes which match the shape of [texture].
## This splits the shape up into multiple segments to support hollow shapes. Don't use it unless
## you have to.
static func create_polygons_from_texture_hollow(
		texture: Texture2D,
		precision: float = 2.0,
		segments = 2,
) -> Array[CollisionPolygon2D]:
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())

	var collision_polygons: Array[CollisionPolygon2D] = []

	var num_segments := Vector2i(segments, segments)
	var segment_size := Vector2i(
		ceili(texture.get_width() as float / num_segments.x),
		ceili(texture.get_height() as float / num_segments.y),
	)

	for x: int in range(0, num_segments.x):
		for y: int in range(0, num_segments.y):
			var rect := Rect2i(
				x * segment_size.x,
				y * segment_size.y,
				segment_size.x,
				segment_size.y,
			)
			var bitmap_polygons := bitmap.opaque_to_polygons(rect, precision)

			for i: int in range(bitmap_polygons.size()):
				var new_collision_polygon := CollisionPolygon2D.new()
				new_collision_polygon.polygon = bitmap_polygons[i]
				new_collision_polygon.position.x = -segment_size.x + x * segment_size.x
				new_collision_polygon.position.y = -segment_size.y + y * segment_size.y
				collision_polygons.push_back(new_collision_polygon)

	return collision_polygons


## Generates and returns an array of collision polygon nodes which match the shape of [texture]
## SG version
static func create_sgpolygons_from_texture(
		texture: Texture2D,
		precision: float = 2.0,
) -> Array[SGCollisionPolygon2D]:
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())

	var rect := Rect2i(0, 0, texture.get_width(), texture.get_height())
	var bitmap_polygons := bitmap.opaque_to_polygons(rect, precision)

	var collision_polygons: Array[SGCollisionPolygon2D] = []

	for i: int in range(bitmap_polygons.size()):
		# SG doesn't like convex polygons, so we need to manually divide it into triangles
		var bitmap_poly := bitmap_polygons[i]
		var convex_polys := GeomUtil.convcave_poly_to_convex_polys(bitmap_poly)
		for concave_poly: PackedVector2Array in convex_polys:
			# Create a physics polygon from that array
			var new_collision_polygon := SGCollisionPolygon2D.new()
			new_collision_polygon.polygon = concave_poly
			new_collision_polygon.fixed_position_x -= SGFixed.mul(
				texture.get_width() * SGFixed.ONE,
				SGFixed.HALF,
			)
			new_collision_polygon.fixed_position_y -= SGFixed.mul(
				texture.get_height() * SGFixed.ONE,
				SGFixed.HALF,
			)
			collision_polygons.push_back(new_collision_polygon)

	return collision_polygons


## Generates and returns an array of collision polygon nodes which match the shape of [texture].
## This splits the shape up into multiple segments to support hollow shapes. Prefer the non-hollow
## version unless you really have to use this one.
## SG VERSION.
static func create_sgpolygons_from_texture_hollow(
		texture: Texture2D,
		precision: float = 2.0,
		segments = 2,
) -> Array[SGCollisionPolygon2D]:
	var tex_width = texture.get_width()
	var tex_height = texture.get_height()

	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())

	var collision_polygons: Array[SGCollisionPolygon2D] = []

	var num_segments := Vector2i(segments, segments)
	var segment_size := Vector2i(
		ceili(tex_width as float / num_segments.x),
		ceili(tex_height as float / num_segments.y),
	)

	for x: int in range(0, num_segments.x):
		for y: int in range(0, num_segments.y):
			var rect := Rect2i(
				x * segment_size.x,
				y * segment_size.y,
				segment_size.x,
				segment_size.y,
			)
			var bitmap_polygons := bitmap.opaque_to_polygons(rect, precision)
			for i: int in range(bitmap_polygons.size()):
				var convex_polys := GeomUtil.convcave_poly_to_convex_polys(bitmap_polygons[i])
				for convex_poly: PackedVector2Array in convex_polys:
					var new_collision_polygon := SGCollisionPolygon2D.new()
					new_collision_polygon.polygon = convex_poly
					new_collision_polygon.fixed_position_x = (
						(ceili(-tex_width * 0.5) + x * segment_size.x) * SGFixed.ONE
					)
					new_collision_polygon.fixed_position_y = (
						(ceili(-tex_height * 0.5) + y * segment_size.y) * SGFixed.ONE
					)
					collision_polygons.push_back(new_collision_polygon)

	return collision_polygons


## Convert a polygon in the form of an array of points into bunch of seperate arrays representing
## the individual triangles that it is formed of.
## Useful for converting convex polygons into triangles for physics stuff.
static func polygon_to_triangles(poly: PackedVector2Array) -> Array[PackedVector2Array]:
	var triangles: Array[PackedVector2Array] = []

	var tri_indices := Geometry2D.triangulate_polygon(poly)

	for tri_index: int in range(0, tri_indices.size(), 3):
		var p1 := poly[tri_indices[tri_index]]
		var p2 := poly[tri_indices[tri_index + 1]]
		var p3 := poly[tri_indices[tri_index + 2]]
		var tri_poly := PackedVector2Array([p1, p2, p3])
		triangles.push_back(tri_poly)

	return triangles


## Uses Hertel-Mehlhorn algorithm to convert a concave polygon into as few convex polygons as
## possible.
static func convcave_poly_to_convex_polys(concave: PackedVector2Array) -> Array[PackedVector2Array]:
	var polygon_indices := _triangulate(concave)
	var merged := true

	# Keep going through and merging polygons until there are no more to merge
	while merged:
		merged = false
		for i: int in range(polygon_indices.size()):
			for j: int in range(i + 1, polygon_indices.size()):
				var shared_edge := _find_shared_edge(polygon_indices[i], polygon_indices[j])
				if shared_edge.size() > 0:
					if _can_merge(polygon_indices[i], polygon_indices[j], shared_edge, concave):
						polygon_indices[i] = _merge_polygons(
							polygon_indices[i], polygon_indices[j], shared_edge
						)
						polygon_indices.remove_at(j)
						merged = true
						break
			if merged:
				break

	var final_polygons: Array[PackedVector2Array] = []
	for index_list: PackedInt32Array in polygon_indices:
		var polygon_points: Array[Vector2] = []
		for index: int in index_list:
			polygon_points.push_back(concave[index])
		final_polygons.push_back(polygon_points)

	return final_polygons


static func _triangulate(poly: PackedVector2Array) -> Array[PackedInt32Array]:
	var triangles: Array[PackedInt32Array] = []
	var tri_indices := Geometry2D.triangulate_polygon(poly)
	for tri_index: int in range(0, tri_indices.size(), 3):
		var i1 := tri_indices[tri_index]
		var i2 := tri_indices[tri_index + 1]
		var i3 := tri_indices[tri_index + 2]
		var tri_poly := PackedInt32Array([i1, i2, i3])
		triangles.push_back(tri_poly)

	return triangles


static func _find_shared_edge(poly_1: Array[int], poly_2: Array[int]) -> Array[int]:
	for i: int in range(poly_1.size()):
		var a := poly_1[i]
		var b := poly_1[(i + 1) % poly_1.size()]
		for j: int in range(poly_2.size()):
			var c := poly_2[j]
			var d := poly_2[(j + 1) % poly_2.size()]
			if a == d and b == c:
				return [a, b]

	return []


static func _can_merge(
	poly_1: Array[int], poly_2: Array[int], edge: Array[int], points: Array[Vector2]
) -> bool:
	var v1 := edge[0]
	var v2 := edge[1]

	var n1_1 := _get_neighbors(poly_1, v1)
	var n1_2 := _get_neighbors(poly_2, v1)
	var n2_1 := _get_neighbors(poly_1, v2)
	var n2_2 := _get_neighbors(poly_2, v2)

	return (
		_is_angle_convex(points[n1_1[0]], points[v1], points[n1_2[1]])
		and _is_angle_convex(points[n2_2[0]], points[v2], points[n2_1[1]])
	)


static func _get_neighbors(poly: Array[int], v: int) -> Array[int]:
	var idx := poly.find(v)
	return [poly[(idx + poly.size() - 1) % poly.size()], poly[(idx + 1) % poly.size()]]


static func _is_angle_convex(p1: Vector2, p2: Vector2, p3: Vector2) -> bool:
	var cross_product := (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
	return cross_product >= 0


static func _merge_polygons(poly_1: Array[int], poly_2: Array[int], edge: Array[int]) -> Array[int]:
	var v1 := edge[0]
	var v2 := edge[1]
	var res: Array[int] = []

	var i := poly_1.find(v2)
	for k: int in range(0, poly_1.size()):
		res.push_back(poly_1[(i + k) % poly_1.size()])

	var j := poly_2.find(v1)
	for k: int in range(1, poly_2.size() - 1):
		res.push_back(poly_2[(j + k) % poly_2.size()])

	return res
