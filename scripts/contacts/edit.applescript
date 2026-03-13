using terms from application "Contacts"

on run argv
	if (count of argv) is not 6 then return my jsonError("Internal error: invalid edit arguments")

	set selectorMode to item 1 of argv
	set selectorValue to item 2 of argv
	set phoneValue to item 3 of argv
	set emailValue to item 4 of argv
	set organizationValue to item 5 of argv
	set titleValue to item 6 of argv

	set updatedId to ""
	set updatedName to ""
	set changeItems to {}

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

			if organizationValue is not "" then
				set organization of targetPerson to organizationValue
				set end of changeItems to my jsonString("organization")
			end if

			if titleValue is not "" then
				set job title of targetPerson to titleValue
				set end of changeItems to my jsonString("jobTitle")
			end if

			if phoneValue is not "" then
				tell targetPerson to make new phone at end of phones with properties {label:"mobile", value:phoneValue}
				set end of changeItems to my jsonString("phone")
			end if

			if emailValue is not "" then
				tell targetPerson to make new email at end of emails with properties {label:"home", value:emailValue}
				set end of changeItems to my jsonString("email")
			end if

			save

			try
				set rawId to id of targetPerson
				if rawId is not missing value then set updatedId to rawId as text
			end try
			try
				set rawName to name of targetPerson
				if rawName is not missing value then set updatedName to rawName as text
			end try
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	return "{\"success\":true,\"message\":" & my jsonString("Updated: " & updatedName) & ",\"id\":" & my jsonString(updatedId) & ",\"changes\":[" & (my joinTextList(changeItems, ",")) & "]}"
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

on joinTextList(values, delimiterText)
	if (count of values) is 0 then return ""
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiterText
	set joinedText to values as text
	set AppleScript's text item delimiters to oldDelimiters
	return joinedText
end joinTextList

end using terms from
