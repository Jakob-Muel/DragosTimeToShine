class_name TalentMinigame
extends Control

## Shared, persistence-free contract for every talent minigame.
## Screens provide a session before the node enters the tree. The minigame reports one
## serializable result; only GameState is allowed to turn that result into progression.

signal score_changed(score: int)
signal status_changed(status: Dictionary)
signal run_completed(result: Dictionary)
signal run_cancelled

var talent_session: Dictionary = {}
var _talent_result_emitted := false


func configure(session: Dictionary) -> void:
	talent_session = session.duplicate(true)
	_talent_result_emitted = false


func start_run() -> void:
	pass


func cancel_run() -> void:
	if _talent_result_emitted:
		return
	_talent_result_emitted = true
	run_cancelled.emit.call_deferred()


func complete_talent_run(raw_score: int, metrics: Dictionary = {}) -> void:
	if _talent_result_emitted:
		return
	_talent_result_emitted = true
	var result := {
		"run_id": String(talent_session.get("run_id", "")),
		"dragon_id": String(talent_session.get("dragon_id", "")),
		"talent_id": String(talent_session.get("talent_id", "")),
		"raw_score": maxi(0, raw_score),
		"metrics": metrics.duplicate(true),
	}
	run_completed.emit.call_deferred(result)
