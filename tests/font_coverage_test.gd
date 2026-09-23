extends SceneTree

const COMIC_REGULAR := UiTokens.FONT_REGULAR
const COMIC_BOLD := UiTokens.FONT_BOLD
const NUMERIC := UiTokens.FONT_NUMERIC
const REQUIRED_CHARACTERS := (
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	+ "0123456789äöüÄÖÜß.,:;!?%+-/()"
)
const ICON_CHARACTERS_PENDING_SPRITES := "♥✦⚑→∞"


func _init() -> void:
	for font: Font in [COMIC_REGULAR, COMIC_BOLD, UiTokens.FONT_HEAVY]:
		for character in REQUIRED_CHARACTERS:
			assert(
				font.has_char(character.unicode_at(0)),
				(
					"Nunito must contain '%s' without relying on system fallback."
					% character
				)
			)
	for character in "0123456789%/.,":
		assert(
			NUMERIC.has_char(character.unicode_at(0)),
			"The numeric UI face must contain '%s'." % character
		)
	var fallback_characters := ""
	for character in ICON_CHARACTERS_PENDING_SPRITES:
		if not COMIC_BOLD.has_char(character.unicode_at(0)):
			fallback_characters += character
	if not fallback_characters.is_empty():
		print(
			"Font icons still using system fallback until their sprite pass: ",
			fallback_characters
		)
	print("Font coverage test: valid")
	quit()
