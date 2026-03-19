using terms from application "Contacts"

on run argv
	if (count of argv) is greater than 0 then return my jsonError("Usage: osascript scripts/applescripts/contact/groups.applescript")

	set dataItems to {}

	try
		tell application "Contacts"
			activate
			delay 0.2

			set groupList to groups
			repeat with groupRef in groupList
				set groupObj to contents of groupRef
				set groupName to ""
				set groupCount to 0

				try
					set rawName to name of groupObj
					if rawName is not missing value then set groupName to rawName as text
				end try

				try
					set groupCount to count of (people of groupObj)
				end try

				set end of dataItems to "{\"name\":" & my jsonString(groupName) & ",\"count\":" & (groupCount as text) & "}"
			end repeat
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	return "{\"success\":true,\"count\":" & ((count of dataItems) as text) & ",\"data\":[" & (my joinTextList(dataItems, ",")) & "]}"
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
