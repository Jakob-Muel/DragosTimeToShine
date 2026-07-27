extends Node

signal locale_changed(locale: String)

const CATALOG_PATH := "res://localization/strings.json"
const DEFAULT_LOCALE := "en"

var _catalog: Dictionary = {}
var _active_locale := DEFAULT_LOCALE


func _ready() -> void:
	_load_catalog()
	set_locale(DEFAULT_LOCALE)


func _load_catalog() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open localization catalog: " + CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Localization catalog must contain a JSON object.")
		return
	_catalog = parsed
	for locale_code: String in _catalog:
		var messages: Variant = _catalog[locale_code]
		if not messages is Dictionary:
			continue
		var translation := Translation.new()
		translation.locale = locale_code
		for key: String in messages:
			translation.add_message(StringName(key), String(messages[key]))
		TranslationServer.add_translation(translation)


func text(key: String, values: Dictionary = {}) -> String:
	var translated := tr(key)
	if values.is_empty():
		return translated
	return translated.format(values)


func set_locale(locale_code: String) -> void:
	if not _catalog.has(locale_code):
		locale_code = DEFAULT_LOCALE
	_active_locale = locale_code
	TranslationServer.set_locale(locale_code)
	locale_changed.emit(locale_code)


func cycle_locale() -> void:
	var locales := available_locales()
	if locales.is_empty():
		return
	var current_index := locales.find(_active_locale)
	set_locale(locales[(current_index + 1) % locales.size()])


func get_locale() -> String:
	return _active_locale


func available_locales() -> PackedStringArray:
	var result := PackedStringArray()
	for locale_code: String in _catalog:
		result.append(locale_code)
	result.sort()
	return result
