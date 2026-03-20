using terms from application "Contacts"

on run argv
	if (count of argv) is not 7 then return my jsonError("Internal error: invalid add arguments")

	set firstNameValue to item 1 of argv
	set lastNameValue to item 2 of argv
	set phoneValue to item 3 of argv
	set emailValue to item 4 of argv
	set organizationValue to item 5 of argv
	set titleValue to item 6 of argv
	set birthdayValue to item 7 of argv

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
			if birthdayValue is not "" then set birth date of newPerson to my parseBirthdayValue(birthdayValue)

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

on parseBirthdayValue(dateText)
	if (length of dateText) is 5 then
		set normalizedDate to "1604-" & dateText
	else if (length of dateText) is 10 then
		set normalizedDate to dateText
	else
		error "Invalid --birthday: " & dateText & ". Use MM-DD or YYYY-MM-DD"
	end if

	if text 5 of normalizedDate is not "-" or text 8 of normalizedDate is not "-" then error "Invalid --birthday: " & dateText & ". Use MM-DD or YYYY-MM-DD"

	try
		set yearValue to (text 1 thru 4 of normalizedDate) as integer
		set monthValue to (text 6 thru 7 of normalizedDate) as integer
		set dayValue to (text 9 thru 10 of normalizedDate) as integer
	on error
		error "Invalid --birthday: " & dateText & ". Use MM-DD or YYYY-MM-DD"
	end try

	if monthValue is less than 1 or monthValue is greater than 12 then error "Invalid --birthday month: " & dateText
	if dayValue is less than 1 or dayValue is greater than 31 then error "Invalid --birthday day: " & dateText

	set parsedDate to current date
	set year of parsedDate to yearValue
	set month of parsedDate to my monthFromNumber(monthValue)
	set day of parsedDate to dayValue
	set time of parsedDate to (12 * hours)
	if my formatDateISO(parsedDate) is not normalizedDate then error "Invalid --birthday date: " & dateText
	return parsedDate
end parseBirthdayValue

on monthFromNumber(monthValue)
	if monthValue is 1 then return January
	if monthValue is 2 then return February
	if monthValue is 3 then return March
	if monthValue is 4 then return April
	if monthValue is 5 then return May
	if monthValue is 6 then return June
	if monthValue is 7 then return July
	if monthValue is 8 then return August
	if monthValue is 9 then return September
	if monthValue is 10 then return October
	if monthValue is 11 then return November
	if monthValue is 12 then return December
	error "Invalid --birthday month number: " & (monthValue as text)
end monthFromNumber

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
