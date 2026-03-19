using terms from application "Contacts"

on run argv
	if (count of argv) is greater than 0 then return my jsonError("Usage: osascript scripts/applescripts/contact/doctor.applescript")

	try
		tell application "Contacts"
			activate
			delay 0.2
			set peopleCount to count of people
			set groupCount to count of groups
		end tell
	on error errMsg
		return my jsonError("Contacts automation check failed: " & errMsg)
	end try

	return "{\"success\":true,\"data\":{\"app\":\"Contacts\",\"automationAccess\":true,\"peopleCount\":" & (peopleCount as text) & ",\"groupCount\":" & (groupCount as text) & "}}"
end run

on replaceText(findText, replacementText, sourceText)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set textParts to text items of sourceText
	set AppleScript's text item delimiters to replacementText
	set replacedText to textParts as text
	set AppleScript's text item delimiters to oldDelimiters
	return replacedText
end replaceText

on jsonEscape(valueText)
	if valueText is missing value then return ""
	set escaped to valueText as text
	set escaped to my replaceText("\\", "\\\\", escaped)
	set escaped to my replaceText("\"", "\\\"", escaped)
	set escaped to my replaceText(linefeed, "\\n", escaped)
	set escaped to my replaceText(return, "\\n", escaped)
	set escaped to my replaceText(character id 9, "\\t", escaped)
	return escaped
end jsonEscape

on jsonString(valueText)
	return "\"" & (my jsonEscape(valueText)) & "\""
end jsonString

on jsonError(errorText)
	return "{\"success\":false,\"error\":" & my jsonString(errorText) & "}"
end jsonError

end using terms from
