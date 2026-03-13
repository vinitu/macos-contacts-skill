-- Shared helpers for Contacts AppleScript scripts. Load via: load script (POSIX file (scriptsDir & "/_lib.applescript"))

on jsonEscape(valueText)
	if valueText is missing value then return ""
	set s to valueText as text
	set s to my replaceText("\\", "\\\\", s)
	set s to my replaceText("\"", "\\\"", s)
	set s to my replaceText(linefeed, "\\n", s)
	set s to my replaceText(return, "\\n", s)
	set s to my replaceText(character id 9, "\\t", s)
	return s
end jsonEscape

on replaceText(findText, replacementText, sourceText)
	set AppleScript's text item delimiters to findText
	set textParts to text items of sourceText
	set AppleScript's text item delimiters to replacementText
	set replacedText to textParts as text
	set AppleScript's text item delimiters to ""
	return replacedText
end replaceText

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
	return "other"
end normalizeLabel
