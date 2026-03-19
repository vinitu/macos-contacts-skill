using terms from application "Contacts"

on run argv
	if (count of argv) is not 2 then return my jsonError("Internal error: invalid get arguments")

	set selectorMode to item 1 of argv
	set selectorValue to item 2 of argv
	set matchedPeople to {}

	try
		tell application "Contacts"
			activate
			delay 0.2

			if selectorMode is "id" then
				set matchedPeople to every person whose id is selectorValue
			else
				set matchedPeople to every person whose name is selectorValue
			end if
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	if (count of matchedPeople) is 0 then
		return my jsonError("Contact not found: " & selectorValue)
	end if

	set dataItems to {}
	repeat with personRef in matchedPeople
		set end of dataItems to my personDetailJson(contents of personRef)
	end repeat

	return "{\"success\":true,\"count\":" & ((count of matchedPeople) as text) & ",\"data\":[" & (my joinTextList(dataItems, ",")) & "]}"
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

on padNumber(numberValue, minWidth)
	set valueText to (numberValue as integer) as text
	repeat while (length of valueText) is less than minWidth
		set valueText to "0" & valueText
	end repeat
	return valueText
end padNumber

on formatDateISO(dateValue)
	try
		set yearValue to year of dateValue as integer
		set monthValue to month of dateValue as integer
		set dayValue to day of dateValue as integer
		return (my padNumber(yearValue, 4)) & "-" & (my padNumber(monthValue, 2)) & "-" & (my padNumber(dayValue, 2))
	on error
		return ""
	end try
end formatDateISO

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

on addressEntriesJson(personRef)
	set jsonEntries to {}

	try
		set addressList to addresses of personRef
		repeat with addressRef in addressList
			set addressObj to contents of addressRef

			set labelText to "other"
			try
				set rawLabel to label of addressObj
				if rawLabel is not missing value then set labelText to rawLabel as text
			end try
			set normalizedLabel to my normalizeLabel(labelText)

			set streetText to ""
			set cityText to ""
			set zipText to ""
			set countryText to ""

			try
				set rawStreet to street of addressObj
				if rawStreet is not missing value then set streetText to rawStreet as text
			end try
			try
				set rawCity to city of addressObj
				if rawCity is not missing value then set cityText to rawCity as text
			end try
			try
				set rawZip to zip of addressObj
				if rawZip is not missing value then set zipText to rawZip as text
			end try
			try
				set rawCountry to country of addressObj
				if rawCountry is not missing value then set countryText to rawCountry as text
			end try

			set addressJson to "{\"label\":" & my jsonString(normalizedLabel) & ",\"street\":" & my jsonString(streetText) & ",\"city\":" & my jsonString(cityText) & ",\"zip\":" & my jsonString(zipText) & ",\"country\":" & my jsonString(countryText) & "}"
			set end of jsonEntries to addressJson
		end repeat
	end try

	return jsonEntries
end addressEntriesJson

on personDetailJson(personRef)
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

	try
		set rawFirstName to first name of personRef
		if rawFirstName is not missing value then
			set firstNameValue to rawFirstName as text
			if firstNameValue is not "" then set end of jsonFields to "\"firstName\":" & my jsonString(firstNameValue)
		end if
	end try

	try
		set rawLastName to last name of personRef
		if rawLastName is not missing value then
			set lastNameValue to rawLastName as text
			if lastNameValue is not "" then set end of jsonFields to "\"lastName\":" & my jsonString(lastNameValue)
		end if
	end try

	set phoneEntries to my phoneEntriesJson(personRef)
	if (count of phoneEntries) is greater than 0 then
		set end of jsonFields to "\"phones\":[" & (my joinTextList(phoneEntries, ",")) & "]"
	end if

	set emailEntries to my emailEntriesJson(personRef)
	if (count of emailEntries) is greater than 0 then
		set end of jsonFields to "\"emails\":[" & (my joinTextList(emailEntries, ",")) & "]"
	end if

	set addressEntries to my addressEntriesJson(personRef)
	if (count of addressEntries) is greater than 0 then
		set end of jsonFields to "\"addresses\":[" & (my joinTextList(addressEntries, ",")) & "]"
	end if

	try
		set rawOrg to organization of personRef
		if rawOrg is not missing value then
			set orgValue to rawOrg as text
			if orgValue is not "" then set end of jsonFields to "\"organization\":" & my jsonString(orgValue)
		end if
	end try

	try
		set rawJobTitle to job title of personRef
		if rawJobTitle is not missing value then
			set titleValue to rawJobTitle as text
			if titleValue is not "" then set end of jsonFields to "\"jobTitle\":" & my jsonString(titleValue)
		end if
	end try

	try
		set rawBirthDate to birth date of personRef
		if rawBirthDate is not missing value then
			set birthDateText to my formatDateISO(rawBirthDate)
			if birthDateText is not "" then set end of jsonFields to "\"birthday\":" & my jsonString(birthDateText)
		end if
	end try

	try
		set rawNote to note of personRef
		if rawNote is not missing value then
			set noteValue to rawNote as text
			if noteValue is not "" then set end of jsonFields to "\"note\":" & my jsonString(noteValue)
		end if
	end try

	return "{" & (my joinTextList(jsonFields, ",")) & "}"
end personDetailJson

end using terms from
