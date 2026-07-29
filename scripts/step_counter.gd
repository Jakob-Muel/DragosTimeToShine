extends Node

signal permission_changed(granted: bool)
signal steps_ready(start_unix: int, steps: int)
signal step_error(message: String)

const PLUGIN_NAME := "StepCounterPlugin"

var _bridge: Object
var _mock_steps := 0
var _permission_granted := false


func _ready() -> void:
	if Engine.has_singleton(PLUGIN_NAME):
		_bridge = Engine.get_singleton(PLUGIN_NAME)
		_connect_native_signals()
		if _bridge.has_method("has_permission"):
			_permission_granted = bool(_bridge.call("has_permission"))
	else:
		_permission_granted = true


func is_mock() -> bool:
	return _bridge == null


func provider_name() -> String:
	if _bridge != null:
		return "native"
	if OS.get_name() in ["Android", "iOS"]:
		return "missing"
	return "mock"


func has_permission() -> bool:
	return _permission_granted


func request_permission() -> void:
	if _bridge == null:
		_permission_granted = true
		permission_changed.emit(true)
		return
	if not _bridge.has_method("request_permission"):
		step_error.emit("The native step plugin does not expose request_permission().")
		return
	_bridge.call("request_permission")


func query_steps_since(start_unix: int, mock_baseline: int = 0) -> void:
	if _bridge == null:
		var steps := maxi(0, _mock_steps - mock_baseline)
		steps_ready.emit.call_deferred(start_unix, steps)
		return
	if not _bridge.has_method("query_steps_since"):
		step_error.emit("The native step plugin does not expose query_steps_since().")
		return
	_bridge.call("query_steps_since", start_unix)


func add_mock_steps(amount: int) -> void:
	if _bridge != null:
		return
	_mock_steps += maxi(0, amount)


func get_mock_total_steps() -> int:
	return _mock_steps


func _connect_native_signals() -> void:
	if _bridge.has_signal("permission_result"):
		_bridge.connect("permission_result", _on_native_permission_result)
	if _bridge.has_signal("steps_result"):
		_bridge.connect("steps_result", _on_native_steps_result)
	if _bridge.has_signal("step_error"):
		_bridge.connect("step_error", _on_native_error)


func _on_native_permission_result(granted: bool) -> void:
	_permission_granted = granted
	permission_changed.emit(granted)


func _on_native_steps_result(start_unix: int, steps: int) -> void:
	steps_ready.emit(start_unix, maxi(0, steps))


func _on_native_error(message: String) -> void:
	step_error.emit(message)
