using terms from application "Contacts"

on run argv
	if (count of argv) is not 2 then return my jsonError("Internal error: invalid list arguments")

	set groupName to item 1 of argv
	set limitText to item 2 of argv

	try
		set limitValue to limitText as integer
	on error
		return my jsonError("Invalid --limit: " & limitText)
	end try

	set listPeople to {}
	set totalCount to 0
	set dataItems to {}

	try
		tell application "Contacts"
			activate
			delay 0.2

			if groupName is "" then
				set listPeople to every person
			else
				set matchingGroups to every group whose name is groupName
				if (count of matchingGroups) is 0 then return my jsonError("Group not found: " & groupName)
				set listPeople to people of (item 1 of matchingGroups)
			end if

			set totalCount to count of listPeople
			set maxCount to totalCount
			if limitValue is less than maxCount then set maxCount to limitValue

			if maxCount is greater than 0 then
				repeat with idx from 1 to maxCount
					set end of dataItems to my personSummaryJson(item idx of listPeople)
				end repeat
			end if
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	return "{\"success\":true,\"total\":" & (totalCount as text) & ",\"count\":" & ((count of dataItems) as text) & ",\"limit\":" & (limitValue as text) & ",\"data\":[" & (my joinTextList(dataItems, ",")) & "]}"
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

on normalizeLabel(labelText)
	if labelText is missing value then return "other"
	set raw to labelText as text
	if raw is "_$!<Mobile>!$_" then return "mobile"
	if raw is "_$!<Home>!$_" then return "home"
	if raw is "_$!<Work>!$_" then return "work"
	if raw is "_$!<Main>!$_" then return "main"
	if raw is "_$!<Other>!$_" then return "other"
	if raw is "_$!<HomePage>!$_" then return "homepage"
	if raw is "_$!<School>!$_" then return "school"
	if raw is "_$!<iPhone>!$_" then return "iphone"
	if raw is "Phone" then return "phone"

	if raw starts with "_$!<" and raw ends with ">!$_" then
		set innerStart to 5
		set innerEnd to (length of raw) - 4
		if innerEnd is greater than or equal to innerStart then
			set raw to text innerStart thru innerEnd of raw
		end if
	end if

	set raw to my replaceText(" ", "-", raw)
	try
		set raw to do shell script "printf %s " & quoted form of raw & " | tr '[:upper:]' '[:lower:]'"
	end try
	return raw
end normalizeLabel

on phoneEntriesJson(personRef)
	set jsonEntries to {}

	try
		set phoneList to phones of personRef
		repeat with phoneRef in phoneList
			set phoneObj to contents of phoneRef
			set phoneValue to ""
			try
				set rawPhoneValue to value of phoneObj
				if rawPhoneValue is not missing value then set phoneValue to rawPhoneValue as text
			end try

			if phoneValue is not "" then
				set labelText to "other"
				try
					set rawLabel to label of phoneObj
					if rawLabel is not missing value then set labelText to rawLabel as text
				end try

				set normalizedLabel to my normalizeLabel(labelText)
				set end of jsonEntries to "{\"label\":" & my jsonString(normalizedLabel) & ",\"value\":" & my jsonString(phoneValue) & "}"
			end if
		end repeat
	end try

	return jsonEntries
end phoneEntriesJson

on emailEntriesJson(personRef)
	set jsonEntries to {}

	try
		set emailList to emails of personRef
		repeat with emailRef in emailList
			set emailObj to contents of emailRef
			set emailValue to ""
			try
				set rawEmailValue to value of emailObj
				if rawEmailValue is not missing value then set emailValue to rawEmailValue as text
			end try

			if emailValue is not "" then
				set labelText to "other"
				try
					set rawLabel to label of emailObj
					if rawLabel is not missing value then set labelText to rawLabel as text
				end try

				set normalizedLabel to my normalizeLabel(labelText)
				set end of jsonEntries to "{\"label\":" & my jsonString(normalizedLabel) & ",\"value\":" & my jsonString(emailValue) & "}"
			end if
		end repeat
	end try

	return jsonEntries
end emailEntriesJson

on personSummaryJson(personRef)
	set jsonFields to {}
	set personId to ""
	set personName to ""

	try
		set rawId to id of personRef
		if rawId is not missing value then set personId to rawId as text
	end try
	try
		set rawName to name of personRef
		if rawName is not missing value then set personName to rawName as text
	end try

	set end of jsonFields to "\"id\":" & my jsonString(personId)
	set end of jsonFields to "\"name\":" & my jsonString(personName)

	set phoneEntries to my phoneEntriesJson(personRef)
	if (count of phoneEntries) is greater than 0 then
		set end of jsonFields to "\"phones\":[" & (my joinTextList(phoneEntries, ",")) & "]"
	end if

	set emailEntries to my emailEntriesJson(personRef)
	if (count of emailEntries) is greater than 0 then
		set end of jsonFields to "\"emails\":[" & (my joinTextList(emailEntries, ",")) & "]"
	end if

	try
		set rawOrg to organization of personRef
		if rawOrg is not missing value then
			set orgValue to rawOrg as text
			if orgValue is not "" then set end of jsonFields to "\"organization\":" & my jsonString(orgValue)
		end if
	end try

	return "{" & (my joinTextList(jsonFields, ",")) & "}"
end personSummaryJson

end using terms from
