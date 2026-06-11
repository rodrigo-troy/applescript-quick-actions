on run {input, parameters}
	-- Create a new file in the front Finder window's folder (Downloads as fallback).
	-- Prompts for a file name (defaults to "untitled") and a file type via a select widget.
	-- If the chosen name collides with an existing file, appends " 2", " 3", ... until unique.

	set defaultName to "untitled"
	set typeOptions to {"Text (.txt)", "Markdown (.md)", "Rich Text (.rtf)", "HTML (.html)", "CSS (.css)", "JSON (.json)", "XML (.xml)", "CSV (.csv)", "YAML (.yml)", "Shell script (.sh)"}
	set supportedExts to {".txt", ".md", ".rtf", ".html", ".css", ".json", ".xml", ".csv", ".yml", ".sh"}

	try
		set nameDialog to display dialog "Enter file name:" default answer defaultName buttons {"Cancel", "Create"} default button "Create" cancel button "Cancel"
	on error number -128
		return input
	end try
	set userName to text returned of nameDialog

	set typeChoice to choose from list typeOptions default items {"Text (.txt)"} with prompt "Choose file type:" OK button name "Create" cancel button name "Cancel"
	if typeChoice is false then return input
	set typeLabel to item 1 of typeChoice

	set savedDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "("
	set extWithParen to last text item of typeLabel
	set AppleScript's text item delimiters to savedDelims
	set chosenExt to text 1 thru -2 of extWithParen

	if userName is "" then
		set baseName to defaultName
	else
		set baseName to userName
		repeat with ext in supportedExts
			set extStr to ext as string
			if baseName ends with extStr then
				set extLen to length of extStr
				if (length of baseName) > extLen then
					set baseName to text 1 thru (-(extLen + 1)) of baseName
				else
					set baseName to ""
				end if
				exit repeat
			end if
		end repeat
		if baseName is "" then set baseName to defaultName
	end if

	tell application "Finder"
		try
			set currentFolder to target of front Finder window
		on error
			set currentFolder to folder ((path to downloads folder) as text)
		end try

		set finalName to baseName & chosenExt
		set counter to 2
		repeat while (exists file finalName of currentFolder)
			set finalName to baseName & " " & counter & chosenExt
			set counter to counter + 1
		end repeat

		set newFile to make new file at currentFolder with properties {name:finalName}
		select newFile
	end tell

	return input
end run
