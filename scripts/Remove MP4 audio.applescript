on run {input, parameters}
	-- Remove the audio stream from a single MP4 file using FFmpeg stream copy (lossless, fast).

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select an MP4 file in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set mp4Files to {}
		repeat with f in selectedFiles
			set fName to name of f as string
			if fName ends with ".mp4" then
				set end of mp4Files to f
			end if
		end repeat

		if mp4Files is {} then
			display dialog "No MP4 file selected. Please select an MP4 file to remove audio from." buttons {"OK"} default button 1 with icon caution
			return
		end if

		if (count of mp4Files) > 1 then
			display dialog "Please select only 1 MP4 file." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set sourceFile to item 1 of mp4Files as alias
		set parentFolder to container of sourceFile as alias
		set parentFolderPath to POSIX path of parentFolder
		set sourcePath to POSIX path of sourceFile

		set sourceName to name of sourceFile
		set baseName to text 1 thru -5 of sourceName
		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set outputName to baseName & "-muted_" & timestamp & ".mp4"
		set outputPath to parentFolderPath & outputName

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

		set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -c copy -an " & quoted form of outputPath & " 2>&1"

		try
			display notification "Processing..." with title "Removing Audio"
			do shell script ffmpegCmd
			display notification "Created: " & outputName with title "Audio Removed" subtitle "Audio stream dropped"
		on error errMsg
			display dialog "Error processing file:" & return & return & errMsg buttons {"OK"} default button 1 with icon stop
		end try

	end tell

	return input
end run
