extends SceneTree

func _init():
	print("--- GDFlatBuffers CLI Test Runner ---")

	var tests = [
		"res://tests/test_flexbuffer.gd",
		"res://tests/fb_simple/test_simple.gd"
	]

	var all_passed = true

	for test_path in tests:
		print("\nRunning test: ", test_path)
		var script = load(test_path)
		if not script:
			print("FAILED: Could not load script: ", test_path)
			all_passed = false
			continue

		var instance = script.new()
		if not instance.has_method("_run"):
			print("FAILED: Script does not have _run() method: ", test_path)
			all_passed = false
			continue

		instance._run()

		if instance.retcode != OK:
			print("FAILED: Test returned non-OK code: ", instance.retcode)
			for line in instance.output:
				print("  ", line)
			all_passed = false
		else:
			print("PASSED")

	if all_passed:
		print("\nSUCCESS: All tests passed!")
		quit(0)
	else:
		print("\nFAILURE: Some tests failed!")
		quit(1)
