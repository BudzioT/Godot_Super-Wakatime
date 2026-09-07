func plugin_print(msg) -> void:
	"""Print message from plugin"""
	print("[Godot_Super-Wakatime]: %s" % msg)
	
func plugin_print_err(err) -> void:
	"""Inform about error from plugin"""
	push_error("[Godot_Super-Wakatime]: %s" % err)

func set_platform():
	"""Set currently used platform"""
	var platform: String = "linux"
	var architecture: String = "arm64"

	if OS.has_feature("windows") or OS.has_feature("uwp"):
		platform = "windows"
	elif OS.has_feature("linux"):
		platform = "linux"
	elif OS.has_feature("macos"):
		platform = "darwin"
	elif OS.has_feature("android"):
		platform = "android"
	elif OS.has_feature("ios"):
		platform = "ios"
	
	if OS.has_feature("x86_64"):
		architecture = "amd64"
	elif OS.has_feature("x86_32"):
		architecture = "386"
	elif OS.has_feature("arm64"):
		architecture = "arm64"
	elif OS.has_feature("arm32"):
		architecture = "arm32"

	return [platform, architecture]

func get_waka_build(platform: String, architecture: String) -> String:
	"""Return wakatime build for current OS"""
	return "wakatime-cli-%s-%s" % [platform, architecture]

func home_directory(platform: String, plugin_path: String) -> String:
	"""Get home directory from """
	var home = null
	for env in ["WAKATIME_HOME", "USERPROFILE", "HOME"]:
		home = OS.get_environment(env)
		if home:
			if platform == "windows":
				home = home.replace("\\", '/')
			return home
	return plugin_path
	
func config_filepath(platform: String, plugin_path: String) -> String:
	"""Get path to wakatime configuration file"""
	return "%s/.wakatime.cfg" % home_directory(platform, plugin_path)
	
func wakatime_cli_exists(wakatime_cli) -> bool:
	"""Return if wakatime cli tool exists already"""
	return FileAccess.file_exists(wakatime_cli)
	
func wakatime_zip_exists(wakatime_zip: String) -> bool:
	"Check if wakatime zip file exists"
	return FileAccess.file_exists(wakatime_zip)
