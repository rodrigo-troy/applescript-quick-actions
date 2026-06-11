on run {input, parameters}
	-- Convert selected M4A files to MP3 using FFmpeg + libmp3lame.
	-- Prompts once for a quality tier and applies it to every file in the batch.

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select one or more M4A files in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set m4aFiles to {}
		repeat with f in selectedFiles
			set fName to name of f as string
			if fName ends with ".m4a" then
				set end of m4aFiles to f
			end if
		end repeat

		if m4aFiles is {} then
			display dialog "No M4A file selected. Please select one or more M4A files to convert." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set ffmpegPath to ""
		set possiblePaths to {"/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"}

		repeat with testPath in possiblePaths
			try
				do shell script "test -x " & testPath
				set ffmpegPath to testPath as string
				exit repeat
			end try
		end repeat

		if ffmpegPath is "" then
			display dialog "FFmpeg not found. Please install it via Homebrew:" & return & return & "brew install ffmpeg" buttons {"OK"} default button 1 with icon stop
			return
		end if

		set qualityOptions to {"320k - High Quality", "192k - Balanced", "128k - Small File", "64k - Tiny File"}
		set compressionChoice to choose from list qualityOptions default items {"192k - Balanced"} with prompt "Choose MP3 quality:" without multiple selections allowed
		if compressionChoice is false then return

		set choiceText to item 1 of compressionChoice
		if choiceText starts with "320k - High Quality" then
			set audioBitrate to "320k"
		else if choiceText starts with "192k - Balanced" then
			set audioBitrate to "192k"
		else if choiceText starts with "128k - Small File" then
			set audioBitrate to "128k"
		else
			set audioBitrate to "64k"
		end if

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set totalFiles to count of m4aFiles
		set processedCount to 0
		set errorCount to 0
		set errorMessages to ""

		display notification "Converting " & totalFiles & " file(s) to MP3 (" & audioBitrate & ")..." with title "M4A to MP3"

		repeat with sourceRef in m4aFiles
			set sourceFile to sourceRef as alias
			set parentFolder to container of sourceFile as alias
			set parentFolderPath to POSIX path of parentFolder
			set sourcePath to POSIX path of sourceFile
			set sourceName to name of sourceFile
			set baseName to text 1 thru -5 of sourceName
			set outputName to baseName & "-converted_" & timestamp & ".mp3"
			set outputPath to parentFolderPath & outputName

			set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -vn -c:a libmp3lame -b:a " & audioBitrate & " " & quoted form of outputPath & " 2>&1"

			try
				do shell script ffmpegCmd
				set processedCount to processedCount + 1
				display notification "Converted " & (processedCount as string) & " of " & (totalFiles as string) with title "M4A to MP3"
			on error errMsg
				set errorCount to errorCount + 1
				set errorMessages to errorMessages & baseName & ": " & errMsg & return
			end try
		end repeat

		if errorCount is 0 then
			display alert "M4A to MP3 Complete" message (processedCount as string) & " file(s) converted to MP3 at " & audioBitrate & "."
		else
			display alert "M4A to MP3 Complete" message (processedCount as string) & " converted, " & (errorCount as string) & " error(s)." & return & return & errorMessages as warning
		end if

	end tell

	return input
end run
