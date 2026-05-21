on run {input, parameters}
	-- Re-encode selected MP3 files at a user-chosen bitrate using FFmpeg + libmp3lame.
	-- Prompts once for a quality tier and applies it to every file in the batch.

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select one or more MP3 files in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set mp3Files to {}
		repeat with f in selectedFiles
			set fName to name of f as string
			if fName ends with ".mp3" then
				set end of mp3Files to f
			end if
		end repeat

		if mp3Files is {} then
			display dialog "No MP3 file selected. Please select one or more MP3 files to re-encode." buttons {"OK"} default button 1 with icon caution
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

		set qualityOptions to {"320k - High Quality", "192k - Balanced", "128k - Small File", "64k mono - Tiny (voice only)"}
		set compressionChoice to choose from list qualityOptions default items {"192k - Balanced"} with prompt "Choose MP3 bitrate:" without multiple selections allowed
		if compressionChoice is false then return

		set choiceText to item 1 of compressionChoice
		set audioExtraFlags to ""
		if choiceText starts with "320k" then
			set audioBitrate to "320k"
			set bitrateLabel to "320k"
		else if choiceText starts with "192k" then
			set audioBitrate to "192k"
			set bitrateLabel to "192k"
		else if choiceText starts with "128k" then
			set audioBitrate to "128k"
			set bitrateLabel to "128k"
		else
			set audioBitrate to "64k"
			set audioExtraFlags to " -ac 1 -ar 22050"
			set bitrateLabel to "64k-mono"
		end if

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set totalFiles to count of mp3Files
		set processedCount to 0
		set errorCount to 0
		set errorMessages to ""

		display notification "Re-encoding " & totalFiles & " file(s) at " & audioBitrate & "..." with title "Change MP3 Bitrate"

		repeat with i from 1 to totalFiles
			set sourceFile to item i of mp3Files as alias
			set parentFolder to container of sourceFile as alias
			set parentFolderPath to POSIX path of parentFolder
			set sourcePath to POSIX path of sourceFile

			set sourceName to name of sourceFile
			set baseName to text 1 thru -5 of sourceName
			set outputName to baseName & "-" & bitrateLabel & "_" & timestamp & ".mp3"
			set outputPath to parentFolderPath & outputName

			set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -vn -c:a libmp3lame -b:a " & audioBitrate & audioExtraFlags & " " & quoted form of outputPath & " 2>&1"

			try
				do shell script ffmpegCmd
				set processedCount to processedCount + 1
				display notification "Re-encoded " & (processedCount as string) & " of " & (totalFiles as string) with title "Change MP3 Bitrate"
			on error errMsg
				set errorCount to errorCount + 1
				set errorMessages to errorMessages & baseName & ": " & errMsg & return
			end try
		end repeat

		if errorCount is 0 then
			display alert "MP3 Bitrate Complete" message (processedCount as string) & " file(s) re-encoded at " & audioBitrate & "."
		else
			display alert "MP3 Bitrate Complete" message (processedCount as string) & " re-encoded, " & (errorCount as string) & " error(s)." & return & return & errorMessages as warning
		end if

	end tell

	return input
end run
