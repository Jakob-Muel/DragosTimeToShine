extends "res://scripts/screens/training_session_screen.gd"


func build() -> void:
	context["talent_id"] = "flight"
	context["return_route"] = "flight_hub"
	super.build()
