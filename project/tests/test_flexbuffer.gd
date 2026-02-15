extends "res://tests/TestBase.gd"

func test_flexbuffer_primitives():
	var data = [
		null,
		true,
		false,
		123,
		-456,
		123.456,
		"Hello FlexBuffers!",
		PackedByteArray([1, 2, 3, 4, 5])
	]

	for val in data:
		var encoded = FlexBuffer.encode(val)
		var decoded = FlexBuffer.decode(encoded)
		if typeof(decoded) != typeof(val):
			logp("Type mismatch for primitive %s: got %s want %s" % [val, typeof(decoded), typeof(val)])
			runcode |= FAILED
		elif decoded != val:
			logp("Value mismatch for primitive %s: got %s want %s" % [val, decoded, val])
			runcode |= FAILED

		# Test aliases
		var encoded2 = FlexBuffer.var_to_flex(val)
		if encoded2 != encoded:
			logp("Alias encode mismatch for %s" % [val])
			runcode |= FAILED
		var decoded2 = FlexBuffer.flex_to_var(encoded2)
		if decoded2 != val:
			logp("Alias decode mismatch for %s" % [val])
			runcode |= FAILED

func test_flexbuffer_nested():
	var data = {
		"a": 1,
		"b": [1, 2, 3],
		"c": {"d": "e"},
		"f": true
	}

	var encoded = FlexBuffer.encode(data)
	var decoded = FlexBuffer.decode(encoded)
	if typeof(decoded) != typeof(data):
		logp("Type mismatch for nested: got %s want %s" % [typeof(decoded), typeof(data)])
		runcode |= FAILED
	elif decoded != data:
		logp("Value mismatch for nested: got %s want %s" % [decoded, data])
		runcode |= FAILED

func test_flexbuffer_math_types():
	var data = [
		Vector2(1, 2),
		Vector3(1, 2, 3),
		Color(1, 0, 0, 1),
		Rect2(1, 2, 3, 4),
		Transform2D(Vector2(1, 2), Vector2(3, 4), Vector2(5, 6)),
		Vector4(1, 2, 3, 4),
		Plane(1, 2, 3, 4),
		Quaternion(1, 2, 3, 4),
		AABB(Vector3(1, 2, 3), Vector3(4, 5, 6)),
		Transform3D(Basis(), Vector3(1, 2, 3))
	]

	for val in data:
		var encoded = FlexBuffer.encode(val)
		var decoded = FlexBuffer.decode(encoded)
		if typeof(decoded) != typeof(val):
			logp("Type mismatch for math %s: got %s want %s" % [val, typeof(decoded), typeof(val)])
			runcode |= FAILED
		elif decoded != val:
			logp("Value mismatch for math %s: got %s want %s" % [val, decoded, val])
			runcode |= FAILED

func test_flexbuffer_packed_arrays():
	var data = [
		PackedInt32Array([1, 2, 3]),
		PackedInt64Array([1, 2, 3]),
		PackedFloat32Array([1.1, 2.2]),
		PackedFloat64Array([1.1, 2.2]),
		PackedStringArray(["a", "b", "c"]),
		PackedVector2Array([Vector2(1, 2), Vector2(3, 4)]),
		PackedVector3Array([Vector3(1, 2, 3)]),
		PackedColorArray([Color(1, 0, 0)])
	]

	for val in data:
		var encoded = FlexBuffer.encode(val)
		var decoded = FlexBuffer.decode(encoded)
		if typeof(decoded) != typeof(val):
			logp("Type mismatch for %s: got %s want %s" % [val, typeof(decoded), typeof(val)])
			runcode |= FAILED
		elif decoded != val:
			logp("Value mismatch: got %s want %s" % [decoded, val])
			runcode |= FAILED

func test_flexbuffer_object():
	var obj = RefCounted.new()
	# RefCounted doesn't have many storage properties by default that we can test easily
	# But we can at least check if it encodes/decodes as an object of correct class
	var encoded = FlexBuffer.encode(obj)
	var decoded = FlexBuffer.decode(encoded)
	if not decoded is RefCounted:
		logp("Object decode failed: not RefCounted")
		runcode |= FAILED
	elif decoded.get_class() != obj.get_class():
		logp("Object class mismatch: got %s want %s" % [decoded.get_class(), obj.get_class()])
		runcode |= FAILED

func _run() -> void:
	test_flexbuffer_primitives()
	test_flexbuffer_nested()
	test_flexbuffer_math_types()
	test_flexbuffer_packed_arrays()
	test_flexbuffer_object()
	print("All FlexBuffer tests passed!")
	retcode = runcode
