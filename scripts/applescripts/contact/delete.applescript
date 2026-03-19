using terms from application "Contacts"

on run argv
	if (count of argv) is not 2 then return my jsonError("Internal error: invalid delete arguments")

	set selectorMode to item 1 of argv
	set selectorValue to item 2 of argv

	set deletedId to ""
	set deletedName to ""

	try
		tell application "Contacts"
			activate
			delay 0.2

			if selectorMode is "id" then
				set matchedPeople to every person whose id is selectorValue
			else
				set matchedPeople to every person whose name is selectorValue
			end if

			if (count of matchedPeople) is 0 then return my jsonError("Contact not found: " & selectorValue)

			set targetPerson to item 1 of matchedPeople
			try
				set rawId to id of targetPerson
				if rawId is not missing value then set deletedId to rawId as text
			end try
			try
				set rawName to name of targetPerson
				if rawName is not missing value then set deletedName to rawName as text
			end try

			delete targetPerson
			save
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	return "{\"success\":true,\"message\":" & my jsonString("Deleted: " & deletedName) & ",\"id\":" & my jsonString(deletedId) & ",\"name\":" & my jsonString(deletedName) & "}"
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
