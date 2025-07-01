@tool
extends EditorPlugin


#------------------------------- SETUP -------------------------------
# Utilities
var Utils = preload("res://addons/godot_super-wakatime/utils.gd").new()
var DecompressorUtils = preload("res://addons/godot_super-wakatime/decompressor.gd").new()

# Hearbeat class
const HeartBeat = preload("res://addons/godot_super-wakatime/heartbeat.gd")
var last_heartbeat = HeartBeat.new()

# Paths, Urls
const PLUGIN_PATH: String = "res://addons/godot_super-wakatime"
const ZIP_PATH: String = "%s/wakatime.zip" % PLUGIN_PATH

const WAKATIME_URL_FMT: String = \
	"https://github.com/wakatime/wakatime-cli/releases/download/v1.54.0/{wakatime_build}.zip"
const DECOMPERSSOR_URL_FMT: String = \
	"https://github.com/ouch-org/ouch/releases/download/0.3.1/{ouch_build}"

# Names for menu
const API_MENU_ITEM: String = "Wakatime API key"
const CONFIG_MENU_ITEM: String = "Wakatime Config File"

# Directories to grab wakatime from
var wakatime_dir = null
var wakatime_cli = null
var decompressor_cli = null

var ApiKeyPrompt: PackedScene = preload("res://addons/godot_super-wakatime/api_key_prompt.tscn")
var Counter: PackedScene = preload("res://addons/godot_super-wakatime/counter.tscn")

# Set platform
var system_platform: String = Utils.set_platform()[0]
var system_architecture: String = Utils.set_platform()[1]

var debug: bool = false
var last_scene_path: String = ''
var last_file_path: String = ''
var last_time: int = 0
var previous_state: String = ''
const LOG_INTERVAL: int = 60000
var scene_mode: bool = false

var key_get_tries: int = 0
var counter_instance: Node
var current_time: String = "0 hrs, 0 mins"


# #------------------------------- DIRECT PLUGIN FUNCTIONS -------------------------------
func _ready() -> void:
	setup_plugin()
	set_process(true)
	
func _exit_tree() -> void:
	_disable_plugin()
	set_process(false)
	
	
func _physics_process(delta: float) -> void:
	"""Process plugin changes over time"""
	# Every 1000 frames check for updates
	if Engine.get_physics_frames() % 1000 == 0:
		# Check for scene change
		var scene_root = get_editor_interface().get_edited_scene_root()
		if scene_root:
			var current_scene_path = _get_current_scene()
			
			# If currently used scene is different thatn 1000 frames ago, log activity
			if current_scene_path != last_scene_path:
				last_scene_path = current_scene_path
				handle_activity_scene(current_scene_path, false, true)
				
			else:
				# Check for scene updates
				var current_scene = EditorInterface.get_edited_scene_root()
				if current_scene:
					var state = generate_scene_state(current_scene)
					# If current state is different than the previous one, handle activity
					if state != previous_state:
						previous_state = state
						handle_activity_scene(current_scene_path, true)
					# Otherwise just keep scene the same
					else:
						previous_state = state
		else:
			last_scene_path = ''
					
func generate_scene_state(node: Node) -> String:
	"""Generate a scene state identifier"""
	var state = str(node.get_instance_id())
	for child in node.get_children():
		state += str(child.get_instance_id())
	return str(state)
	
func _input(event: InputEvent) -> void:
	"""Handle all input events"""
	# Key events
	if event is InputEventKey:
		var file = get_current_file()
		if file:
			handle_activity(ProjectSettings.globalize_path(file.resource_path))
	# Mouse button events
	elif event is InputEventMouse and event.is_pressed():
		var file = _get_current_scene()
		if file != '' and file:
			handle_activity_scene(file)

func setup_plugin() -> void:
	"""Setup Wakatime plugin, download dependencies if needed, initialize menu"""
	Utils.plugin_print("Setting up %s" % get_user_agent())
	check_dependencies()
	
	# Grab API key if needed
	var api_key = get_api_key()
	if api_key == null:
		request_api_key()
	await get_tree().process_frame
	
	# Add menu buttons
	add_tool_menu_item(API_MENU_ITEM, request_api_key)
	add_tool_menu_item(CONFIG_MENU_ITEM, open_config)
	
	counter_instance = Counter.instantiate()
	add_control_to_bottom_panel(counter_instance, current_time)
	
	# Connect code editor signals
	var script_editor: ScriptEditor = get_editor_interface().get_script_editor()
	script_editor.call_deferred("connect", "editor_script_changed", Callable(self,
		"_on_script_changed"))

func _disable_plugin() -> void:
	"""Cleanup after disabling plugin"""
	# Remove items from menu
	remove_tool_menu_item(API_MENU_ITEM)
	remove_tool_menu_item(CONFIG_MENU_ITEM)
	
	remove_control_from_bottom_panel(counter_instance)
	
	# Disconnect script editor tracking
	var script_editor: ScriptEditor = get_editor_interface().get_script_editor()
	if script_editor.is_connected("editor_script_changed", Callable(self,
		"_on_script_changed")):
		script_editor.disconnect("editor_script_changed", Callable(self,
			"_on_script_changed"))
		
func _on_script_changed(file) -> void:
	"""Handle changing scripts"""
	if file:
		last_file_path = ProjectSettings.globalize_path(file.resource_path)
	handle_activity(last_file_path)
	
#func _unhandled_key_input(event: InputEvent) -> void:
#	"""Handle key inputs"""
#	var file = get_current_file()
#	handle_activity(file)
	
func _save_external_data() -> void:
	"""Handle saving files"""
	var file = get_current_file()
	if file:
		handle_activity(ProjectSettings.globalize_path(file.resource_path), true)
	
func _get_current_scene():
	"""Get currently used scene"""
	if EditorInterface.get_edited_scene_root():
		var file = EditorInterface.get_edited_scene_root()
		if file:
			return ProjectSettings.globalize_path(file.scene_file_path)
	else:
		var file = get_current_file()
		if file:
			return ProjectSettings.globalize_path(file.resource_path)
			
	return null
	
func _on_scene_modified():
	"""Send heartbeat when scene is modified"""
	var current_scene = get_tree().current_scene
	if current_scene:
		handle_activity_scene(_get_current_scene())
	
func get_current_file():
	"""Get currently used script file"""
	var file = get_editor_interface().get_script_editor().get_current_script()
	if file:
		last_file_path = ProjectSettings.globalize_path(file.resource_path)
	
	return get_editor_interface().get_script_editor().get_current_script()
		
func handle_activity(file, is_write: bool = false) -> void:
	"""Handle user's activity"""
	# If file that has activity in or wakatime cli doesn't exist, return
	if not file or not Utils.wakatime_cli_exists(get_waka_cli()):
		return
	
	# If user is saving file or has changed path, or enough time has passed for a heartbeat - send it
	#var filepath = ProjectSettings.globalize_path(file.resource_path)
	if is_write or file != last_heartbeat.file_path or enough_time_passed():
		send_heartbeat(file, is_write)
		
func handle_activity_scene(file, is_write: bool = false, changed_file: bool = false) -> void:
	"""Handle activity in scenes"""
	if not file or not Utils.wakatime_cli_exists(get_waka_cli()):
		return
		
	if is_write or changed_file or enough_time_passed():
		scene_mode = true
		send_heartbeat(file, is_write)
		
func send_heartbeat(filepath: String, is_write: bool) -> void:
	"""Send Wakatimde heartbeat for the specified file"""
	# Check Wakatime API key
	var api_key = get_api_key()
	if api_key == null:
		Utils.plugin_print("Failed to get Wakatime API key. Are you sure it's correct?")
		if (key_get_tries < 3):
			request_api_key()
			key_get_tries += 1
		else:
			Utils.plugin_print("If this keep occuring, please create a file: ~/.wakatime.cfg\n
				initialize it with:\n[settings]\napi_key={your_key}")
		return
		
	# Make sure not to trigger additional heartbeats cause of events from scenes
	var file = filepath
	if scene_mode:
		file = last_file_path
		#print("\n-------SCENE MODE--------\n")
		
	# Create heartbeat
	var heartbeat = HeartBeat.new(file, Time.get_unix_time_from_system(), is_write)
	
	# Current text editor
	var text_editor = _find_active_script_editor()
	var cursor_pos = _get_cursor_pos(text_editor)
	
	# Append all informations as Wakatime CLI arguments
	var cmd: Array[Variant] = ["--entity", filepath, "--key", api_key]
	if is_write:
		cmd.append("--write")
	cmd.append_array(["--alternate-project", ProjectSettings.get("application/config/name")])
	cmd.append_array(["--time", str(heartbeat.time)])
	cmd.append_array(["--lineno", str(cursor_pos.line)])
	cmd.append_array(["--cursorpos", str(cursor_pos.column)])
	cmd.append_array(["--plugin", get_user_agent()])
	
	cmd.append_array(["--alternate-language", "Scene"])
	if scene_mode:
		cmd.append_array(["--category", "building"])
	else:
		cmd.append(["--category", "coding"])
	
	# Send heartbeat using Wakatime CLI
	var cmd_callable = Callable(self, "_handle_heartbeat").bind(cmd)
	
	scene_mode = false
	
	WorkerThreadPool.add_task(cmd_callable)
	last_heartbeat = heartbeat
	
func _find_active_script_editor():
	"""Return currently used script editor"""
	# Get script editor
	var script_editor = get_editor_interface().get_script_editor()
	var current_editor = script_editor.get_current_editor()
	
	# Try to find code editor from it
	if current_editor:
		return _find_code_edit_recursive(script_editor.get_current_editor())
	return null

func _find_code_edit_recursive(node: Node) -> CodeEdit:
	"""Find recursively code editor in a node"""
	# If node is already a code editor, return it
	if node is CodeEdit:
		return node

	# Try to find it in every child of a given node
	for child in node.get_children():
		var editor = _find_code_edit_recursive(child)
		if editor:
			return editor
	return null
	
func _get_cursor_pos(text_editor) -> Dictionary:
	"""Get cursor editor from the given text editor"""
	if text_editor:
		return {
			"line": text_editor.get_caret_line() + 1,
			"column": text_editor.get_caret_column() + 1
		}
		
	return {
		"line": 0,
		"column": 0
	}
	
func _handle_heartbeat(cmd_arguments) -> void:
	"""Handle sending the heartbeat"""
	# Get Wakatime CLI and try to send a heartbeat
	if wakatime_cli == null:
		wakatime_cli = Utils.get_waka_cli()
		
	var output: Array[Variant] = []
	var exit_code: int = OS.execute(wakatime_cli, cmd_arguments, output, true)
	
	update_today_time(wakatime_cli)
		
	# Inform about success or errors if user is in debug
	if debug:
		if exit_code == -1:
			Utils.plugin_print("Failed to send heartbeat: %s" % output)
		else:
			Utils.plugin_print("Heartbeat sent: %s" % output)
			
func enough_time_passed():
	"""Check if enough time has passed for another heartbeat"""
	return Time.get_unix_time_from_system() - last_heartbeat.time >= HeartBeat.FILE_MODIFIED_DELAY
	
func update_today_time(wakatime_cli) -> void:
	"""Update today's time in menu"""
	var output: Array[Variant] = []
	# Get today's time from Wakatime CLI
	var exit_code: int = OS.execute(wakatime_cli, ["--today"], output, true)
	
	# Convert it and combine different categories into
	if exit_code == 0:
		current_time = convert_time(output[0])
	else:
		current_time = "Wakatime"
	#print(current_time)
	call_deferred("_update_panel_label", current_time, output[0])
	
func _update_panel_label(label: String, content: String):
	"""Update bottom panel name that shows time"""
	# If counter exists and it has a label, update both the label and panel's name
	if counter_instance and counter_instance.get_node("HBoxContainer/Label"):
		# Workaround to rename panel
		counter_instance.get_node("HBoxContainer/Label").text = content
		remove_control_from_bottom_panel(counter_instance)
		add_control_to_bottom_panel(counter_instance, label)

		
func convert_time(complex_time: String):
	"""Convert time from complex format into basic one, combine times"""
	var hours: int = 0
	var minutes: int = 0
	
	# Split times into categories
	var time_categories = complex_time.split(', ')
	for category in time_categories:
		# Example category: "2h 25m" or "1h 5m"
		var h_match = category.find("h")
		var m_match = category.find("m")
		if h_match != -1:
			var h_str = category.substr(0, h_match).strip_edges()
			if h_str.is_valid_int():
				hours += int(h_str)
		if m_match != -1:
			var m_str = category.substr(category.rfind(" ", m_match) + 1, m_match - (category.rfind(" ", m_match) + 1)).strip_edges()
			if m_str.is_valid_int():
				minutes += int(m_str)
	
	# Wrap minutes into hours if needed
	while minutes >= 60:
		minutes -= 60
		hours += 1
	return str(hours) + " hrs, " + str(minutes) + " mins"

#------------------------------- FILE FUNCTIONS -------------------------------
func open_config() -> void:
	"""Open wakatime config file"""
	OS.shell_open(Utils.config_filepath(system_platform, PLUGIN_PATH))
	
func get_waka_dir() -> String:
	"""Search for and return wakatime directory"""
	if wakatime_dir == null:
		wakatime_dir = "%s/.wakatime" % Utils.home_directory(system_platform, PLUGIN_PATH)
	return wakatime_dir
	
func get_waka_cli() -> String:
	"""Get wakatime_cli file"""
	if wakatime_cli == null:
		var build = Utils.get_waka_build(system_platform, system_architecture)
		var ext: String = ".exe" if system_platform == "windows" else ''
		wakatime_cli = "%s/%s%s" % [get_waka_dir(), build, ext]
	return wakatime_cli
	
func check_dependencies() -> void:
	"""Make sure all dependencies exist"""
	if !Utils.wakatime_cli_exists(get_waka_cli()):
		download_wakatime()
		if !DecompressorUtils.lib_exists(decompressor_cli, system_platform, PLUGIN_PATH):
			download_decompressor()
	
func download_wakatime() -> void:
	"""Download wakatime cli"""
	Utils.plugin_print("Downloading Wakatime CLI...")
	var url: String = WAKATIME_URL_FMT.format({"wakatime_build":
			Utils.get_waka_build(system_platform, system_architecture)})
	
	# Try downloading wakatime
	var http = HTTPRequest.new()
	http.download_file = ZIP_PATH
	http.connect("request_completed", Callable(self, "_wakatime_download_completed"))
	add_child(http)
	
	# Handle errors
	var status = http.request(url)
	if status != OK:
		Utils.plugin_print_err("Failed to start downloading Wakatime [Error: %s]" % status)
		_disable_plugin()
	
func download_decompressor() -> void:
	"""Download ouch decompressor"""
	Utils.plugin_print("Downloading Ouch! decompression library...")
	var url: String = DECOMPERSSOR_URL_FMT.format({"ouch_build":
			Utils.get_ouch_build(system_platform)})
	if system_platform == "windows":
		url += ".exe"
		
	# Try to download ouch
	var http = HTTPRequest.new()
	http.download_file = DecompressorUtils.decompressor_cli(decompressor_cli, system_platform, PLUGIN_PATH)
	http.connect("request_completed", Callable(self, "_decompressor_download_finished"))
	add_child(http)
	
	# Handle errors
	var status = http.request(url)
	if status != OK:
		_disable_plugin()
		Utils.plugin_print_err("Failed to start downloading Ouch! library [Error: %s]" % status)
		
func _wakatime_download_completed(result, status, headers, body) -> void:
	"""Finish downloading wakatime, handle errors"""
	if result != HTTPRequest.RESULT_SUCCESS:
		Utils.plugin_print_err("Error while downloading Wakatime CLI")
		_disable_plugin()
		return
	
	Utils.plugin_print("Wakatime CLI has been installed succesfully! Located at %s" % ZIP_PATH)
	extract_files(ZIP_PATH, get_waka_dir())
	
func _decompressor_download_finished(result, status, headers, body) -> void:
	"""Handle errors and finishi decompressor download"""
	# Error while downloading
	if result != HTTPRequest.RESULT_SUCCESS:
		Utils.plugin_print_err("Error while downloading Ouch! library")
		_disable_plugin()
		return
	
	# Error while saving
	if !DecompressorUtils.lib_exists(decompressor_cli, system_platform, PLUGIN_PATH):
		Utils.plugin_print_err("Failed to save Ouch! library")
		_disable_plugin()
		return

	# Save decompressor path, give write permissions to it
	var decompressor: String = \
		ProjectSettings.globalize_path(DecompressorUtils.decompressor_cli(decompressor_cli,
			system_platform, PLUGIN_PATH))
			
	if system_platform == "linux" or system_platform == "darwin":
		OS.execute("chmod", ["+x", decompressor], [], true)
		
	# Extract files, allowing usage of Ouch!
	Utils.plugin_print("Ouch! has been installed succesfully! Located at %s" % \
		DecompressorUtils.decompressor_cli(decompressor_cli, system_platform, PLUGIN_PATH))
	extract_files(ZIP_PATH, get_waka_dir())
	
func extract_files(source: String, destination: String) -> void:
	"""Extract downloaded Wakatime zip"""
	# If decompression library and wakatime zip folder don't exist, return
	if not DecompressorUtils.lib_exists(decompressor_cli, system_platform,
			PLUGIN_PATH) and not Utils.wakatime_zip_exists(ZIP_PATH):
		return
		
	# Get paths as global
	Utils.plugin_print("Extracting Wakatime...")
	var decompressor: String
	if system_platform == "windows":
		decompressor = ProjectSettings.globalize_path(
			DecompressorUtils.decompressor_cli(decompressor_cli, system_platform, PLUGIN_PATH))
	else:
		decompressor = ProjectSettings.globalize_path("res://" +
			DecompressorUtils.decompressor_cli(decompressor_cli, system_platform, PLUGIN_PATH))
		
	var src: String = ProjectSettings.globalize_path(source)
	var dest: String = ProjectSettings.globalize_path(destination)
	
	# Execute Ouch! decompression command, catch errors
	var errors: Array[Variant] = []
	var args: Array[String] = ["--yes", "decompress", src, "--dir", dest]
	
	var error: int = OS.execute(decompressor, args, errors, true)
	if error:
		Utils.plugin_print(errors)
		_disable_plugin()
		return
		
	# Results
	if Utils.wakatime_cli_exists(get_waka_cli()):
		Utils.plugin_print("Wakatime CLI installed (path: %s)" % get_waka_cli())
	else:
		Utils.plugin_print_err("Installation of Wakatime failed")
		_disable_plugin()
		
	# Remove leftover files
	clean_files()
	
func clean_files():
	"""Delete files that aren't needed anymore"""
	if Utils.wakatime_zip_exists(ZIP_PATH):
		delete_file(ZIP_PATH)
	if DecompressorUtils.lib_exists(decompressor_cli, system_platform, PLUGIN_PATH):
		delete_file(ZIP_PATH)
		
func delete_file(path: String) -> void:
	"""Delete file at specified path"""
	var dir: DirAccess = DirAccess.open("res://")
	var status: int = dir.remove(path)
	if status != OK:
		Utils.plugin_print_err("Failed to clean unnecesary file at %s" % path)
	else:
		Utils.plugin_print("Clean unncecesary file at %s" % path)

#------------------------------- API KEY FUNCTIONS -------------------------------

func get_api_key():
	"""Get wakatime api key"""
	var result = []
	# Handle errors while getting the key
	var err = OS.execute(get_waka_cli(), ["--config-read", "api_key"], result)
	if err == -1:
		return null
		
	# Trim API key from whitespaces and return it
	var key = result[0].strip_edges()
	if key.is_empty():
		return null
	return key
	
func request_api_key() -> void:
	"""Request Wakatime API key from the user"""
	# Prepare prompt
	var prompt = ApiKeyPrompt.instantiate()
	_set_api_key(prompt, get_api_key())
	_register_api_key_signals(prompt)
	
	# Show prompt and hide it on request
	add_child(prompt)
	prompt.popup_centered()
	await prompt.popup_hide
	prompt.queue_free()
	
func _set_api_key(prompt: PopupPanel, api_key) -> void:
	"""Set API key from prompt"""
	# Safeguard against empty key
	if api_key == null:
		api_key = ''
		
	# Set correct text, to show API key
	var edit_field: Node = prompt.get_node("VBoxContainer/HBoxContainerTop/LineEdit")
	edit_field.text = api_key
	
func _register_api_key_signals(prompt: PopupPanel) -> void:
	"""Connect all signals related to API key popup"""
	# Get all Nodes
	var show_button: Node = prompt.get_node("VBoxContainer/HBoxContainerTop/ShowButton")
	var save_button: Node = prompt.get_node("VBoxContainer/HBoxContainerBottom/SubmitButton")
	
	# Connect them to press events
	show_button.connect("pressed", Callable(self, "_on_toggle_key_text").bind(prompt))
	save_button.connect("pressed", Callable(self, "_on_save_key").bind(prompt))
	prompt.connect("popup_hide", Callable(self, "_on_popup_hide").bind(prompt))
	
func _on_popup_hide(prompt: PopupPanel):
	"""Close the popup window when user wants to hide it"""
	prompt.queue_free()
	
func _on_toggle_key_text(prompt: PopupPanel) -> void:
	"""Handle hiding and showing API key"""
	# Get nodes
	var show_button: Node = prompt.get_node("VBoxContainer/HBoxContainerTop/ShowButton")
	var edit_field: Node = prompt.get_node("VBoxContainer/HBoxContainerTop/LineEdit")
	
	# Set the correct text and hide field if needed
	edit_field.secret = not edit_field.secret
	show_button.text = "Show" if edit_field.secret else "Hide"
	
func _on_save_key(prompt: PopupPanel) -> void:
	"""Handle entering API key"""
	# Get text field node and api key that's entered
	var edit_field: Node = prompt.get_node("VBoxContainer/HBoxContainerTop/LineEdit")
	var api_key = edit_field.text.strip_edges()
	
	# Try to set api key for wakatime and handle errors
	var err: int = OS.execute(get_waka_cli(), ["--config-write", "api-key=%s" % api_key])
	if err == -1:
		Utils.plugin_print("Failed to save API key")
	prompt.visible = false
	
#------------------------------- PLUGIN INFORMATIONS -------------------------------
	
func get_user_agent() -> String:
	"""Get user agent identifier"""
	var os_name = OS.get_name().to_lower()
	return "godot/%s godot-wakatime/%s" % [
		get_engine_version(),
		_get_plugin_version()
	]
	
func _get_plugin_name() -> String:
	"""Get name of the plugin"""
	return "Godot_Super-Wakatime"
	
func _get_plugin_version() -> String:
	"""Get plugin version"""
	return "1.0.0"
	
func _get_editor_name() -> String:
	"""Get name of the editor"""
	return "Godot%s" % get_engine_version()
	
func get_engine_version() -> String:
	"""Get verison of currently used engine"""
	return "%s.%s.%s" % [Engine.get_version_info()["major"], Engine.get_version_info()["minor"],
		Engine.get_version_info()["patch"]]