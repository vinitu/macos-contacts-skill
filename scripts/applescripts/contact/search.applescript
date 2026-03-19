using terms from application "Contacts"

on run argv
	if (count of argv) is not 4 then return my jsonError("Internal error: invalid search arguments")

	set queryText to item 1 of argv
	set fieldName to item 2 of argv
	set limitText to item 3 of argv
	set exactMode to (item 4 of argv) is "true"

	try
		set limitValue to limitText as integer
	on error
		return my jsonError("Invalid --limit: " & limitText)
	end try

	set matchedPeople to {}
	set seenIds to {}

	try
		tell application "Contacts"
			activate
			delay 0.2

			if fieldName is "name" or fieldName is "all" then
				if exactMode then
					set nameMatches to every person whose name is queryText
				else
					set nameMatches to every person whose name contains queryText
				end if

				repeat with personRef in nameMatches
					set personObj to contents of personRef
					set personId to ""
					try
						set rawId to id of personObj
						if rawId is not missing value then set personId to rawId as text
					end try

					if personId is not "" and (my listContainsText(seenIds, personId)) is false then
						set end of seenIds to personId
						set end of matchedPeople to personObj
					end if

					if (count of matchedPeople) is greater than or equal to limitValue then exit repeat
				end repeat
			end if

			if (fieldName is "org" or fieldName is "all") and (count of matchedPeople) is less than limitValue then
				if exactMode then
					set organizationMatches to every person whose organization is queryText
				else
					set organizationMatches to every person whose organization contains queryText
				end if

				repeat with personRef in organizationMatches
					set personObj to contents of personRef
					set personId to ""
					try
						set rawId to id of personObj
						if rawId is not missing value then set personId to rawId as text
					end try

					if personId is not "" and (my listContainsText(seenIds, personId)) is false then
						set end of seenIds to personId
						set end of matchedPeople to personObj
					end if

					if (count of matchedPeople) is greater than or equal to limitValue then exit repeat
				end repeat
			end if

			set shouldScanDetails to false
			if fieldName is "phone" or fieldName is "email" then set shouldScanDetails to true
			if fieldName is "all" and (my isDetailLikeQuery(queryText)) then set shouldScanDetails to true

			if shouldScanDetails and (count of matchedPeople) is less than limitValue then
				set everyone to people
				repeat with personRef in everyone
					if (count of matchedPeople) is greater than or equal to limitValue then exit repeat

					set personObj to contents of personRef
					set personId to ""
					try
						set rawId to id of personObj
						if rawId is not missing value then set personId to rawId as text
					end try

					if personId is "" or (my listContainsText(seenIds, personId)) then
						-- skip known person
					else
						set personMatched to false

						if fieldName is "phone" or fieldName is "all" then
							try
								set phoneList to phones of personObj
								repeat with phoneRef in phoneList
									set phoneValue to ""
									try
										set rawPhoneValue to value of (contents of phoneRef)
										if rawPhoneValue is not missing value then set phoneValue to rawPhoneValue as text
									end try

									if my matchesValue(phoneValue, queryText, exactMode) then
										set personMatched to true
										exit repeat
									end if
								end repeat
							end try
						end if

						if personMatched is false and (fieldName is "email" or fieldName is "all") then
							try
								set emailList to emails of personObj
								repeat with emailRef in emailList
									set emailValue to ""
									try
										set rawEmailValue to value of (contents of emailRef)
										if rawEmailValue is not missing value then set emailValue to rawEmailValue as text
									end try

									if my matchesValue(emailValue, queryText, exactMode) then
										set personMatched to true
										exit repeat
									end if
								end repeat
							end try
						end if

						if personMatched then
							set end of seenIds to personId
							set end of matchedPeople to personObj
						end if
					end if
				end repeat
			end if
		end tell
	on error errMsg
		return my jsonError(errMsg)
	end try

	set dataItems to {}
	repeat with personRef in matchedPeople
		set end of dataItems to my personSummaryJson(contents of personRef)
	end repeat

	return "{\"success\":true,\"count\":" & ((count of matchedPeople) as text) & ",\"limit\":" & (limitValue as text) & ",\"data\":[" & (my joinTextList(dataItems, ",")) & "]}"
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

on listContainsText(values, targetText)
	repeat with valueRef in values
		if (contents of valueRef) is targetText then return true
	end repeat
	return false
end listContainsText

on equalsIgnoreCase(leftText, rightText)
	set leftValue to leftText as text
	set rightValue to rightText as text
	ignoring case
		return (leftValue is rightValue)
	end ignoring
end equalsIgnoreCase

on containsIgnoreCase(haystackText, needleText)
	set haystackValue to haystackText as text
	set needleValue to needleText as text
	ignoring case
		return (haystackValue contains needleValue)
	end ignoring
end containsIgnoreCase

on matchesValue(candidateText, queryText, exactMode)
	if candidateText is missing value then return false
	set candidateValue to candidateText as text
	if candidateValue is "" then return false

	if exactMode then
		return my equalsIgnoreCase(candidateValue, queryText)
	end if

	return my containsIgnoreCase(candidateValue, queryText)
end matchesValue

on isDetailLikeQuery(queryText)
	set queryValue to queryText as text
	if queryValue is "" then return false
	if queryValue contains "@" then return true
	if queryValue contains "+" then return true

	repeat with digitText in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
		if queryValue contains (contents of digitText) then return true
	end repeat

	return false
end isDetailLikeQuery

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
