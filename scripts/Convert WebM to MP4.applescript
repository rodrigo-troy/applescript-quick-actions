on run {input, parameters}
	-- Convert selected WebM files to MP4 using FFmpeg (hardware-accelerated H.264 encoding).
	-- Prompts once for a quality tier and applies it to every file in the batch.

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select one or more WebM files in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set webmFiles to {}
		repeat with f in selectedFiles
			set fName to name of f as string
			if fName ends with ".webm" then
				set end of webmFiles to f
			end if
		end repeat

		if webmFiles is {} then
			display dialog "No WebM file selected. Please select one or more WebM files to convert." buttons {"OK"} default button 1 with icon caution
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

		set compressionChoice to button returned of (display dialog "Choose compression level:" buttons {"High Quality", "Balanced", "Small File"} default button "Balanced" with icon note)

		if compressionChoice is "High Quality" then
			set videoQuality to "75"
			set audioBitrate to "192k"
		else if compressionChoice is "Balanced" then
			set videoQuality to "55"
			set audioBitrate to "160k"
		else
			set videoQuality to "35"
			set audioBitrate to "128k"
		end if

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set totalFiles to count of webmFiles
		set processedCount to 0
		set errorCount to 0
		set errorMessages to ""

		display notification "Converting " & totalFiles & " file(s) to MP4 (" & compressionChoice & ")..." with title "WebM to MP4"

		repeat with sourceRef in webmFiles
			set sourceFile to sourceRef as alias
			set parentFolder to container of sourceFile as alias
			set parentFolderPath to POSIX path of parentFolder
			set sourcePath to POSIX path of sourceFile

			set sourceName to name of sourceFile
			set baseName to text 1 thru -6 of sourceName
			set outputName to baseName & "-converted_" & timestamp & ".mp4"
			set outputPath to parentFolderPath & outputName

			set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -c:v h264_videotoolbox -q:v " & videoQuality & " -c:a aac -b:a " & audioBitrate & " " & quoted form of outputPath & " 2>&1"

			try
				do shell script ffmpegCmd
				set processedCount to processedCount + 1
				display notification "Converted " & (processedCount as string) & " of " & (totalFiles as string) with title "WebM to MP4"
			on error errMsg
				set errorCount to errorCount + 1
				set errorMessages to errorMessages & baseName & ": " & errMsg & return
			end try
		end repeat

		if errorCount is 0 then
			display alert "WebM to MP4 Complete" message (processedCount as string) & " file(s) converted to MP4 (" & compressionChoice & ")."
		else
			display alert "WebM to MP4 Complete" message (processedCount as string) & " converted, " & (errorCount as string) & " error(s)." & return & return & errorMessages as warning
		end if
	end tell

	return input
end run
