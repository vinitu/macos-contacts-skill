using terms from application "Contacts"

on run argv
	if (count of argv) is not 6 then return my jsonError("Internal error: invalid add arguments")

	set firstNameValue to item 1 of argv
	set lastNameValue to item 2 of argv
	set phoneValue to item 3 of argv
	set emailValue to item 4 of argv
	set organizationValue to item 5 of argv
	set titleValue to item 6 of argv

	set createdId to ""
	set createdName to ""

	try
		tell application "Contacts"
			activate
			delay 0.2

			set newPerson to make new person
			if firstNameValue is not "" then set first name of newPerson to firstNameValue
			if lastNameValue is not "" then set last name of newPerson to lastNameValue
			if organizationValue is not "" then set organization of newPerson to organizationValue
			if titleValue is not "" then set job title of newPerson to titleValue

			if phoneValue is not "" then
				tell newPerson to make new phone at end of phones with properties {label:"mobile", value:phoneValue}
			end if

			if emailValue is not "" then
				tell newPerson to make new email at end of emails with properties {label:"home", value:emailValue}
			end if

			save

			try
				set rawId to id of newPerson
				if rawId is not missing value then set createdId to rawId as text
			end try
			try
				set rawName to name of newPerson
				if rawName is not missing value then set createdName to rawName as text
			end try
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	return "{\"success\":true,\"message\":" & my jsonString("Contact created: " & createdName) & ",\"id\":" & my jsonString(createdId) & ",\"name\":" & my jsonString(createdName) & "}"
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
