on run {input, parameters}
	-- Upscale one or more MP4 videos to double their resolution (2x width, 2x height) using
	-- FFmpeg with the lanczos resampler and hardware-accelerated h264_videotoolbox encoding.
	-- Per-file errors don't abort the batch; a summary alert reports processed/error counts.

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select one or more MP4 files in Finder first." buttons {"OK"} default button 1 with icon caution
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
			display dialog "No MP4 file selected. Please select one or more MP4 files to upscale." buttons {"OK"} default button 1 with icon caution
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

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set totalFiles to count of mp4Files
		set processedCount to 0
		set errorCount to 0
		set errorMessages to ""

		display notification "Upscaling " & totalFiles & " video(s)... this may take a while" with title "Upscale MP4 Video"

		repeat with sourceRef in mp4Files
			set sourceFile to sourceRef as alias
			set parentFolder to container of sourceFile as alias
			set parentFolderPath to POSIX path of parentFolder
			set sourcePath to POSIX path of sourceFile

			set sourceName to name of sourceFile
			set baseName to text 1 thru -5 of sourceName
			set outputName to baseName & "-upscaled_" & timestamp & ".mp4"
			set outputPath to parentFolderPath & outputName

			set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -vf \"scale=iw*2:ih*2:flags=lanczos\" -c:v h264_videotoolbox -b:v 20M -c:a copy " & quoted form of outputPath & " 2>&1"

			try
				do shell script ffmpegCmd
				set processedCount to processedCount + 1
				display notification "Upscaled " & (processedCount as string) & " of " & (totalFiles as string) with title "Upscale MP4 Video"
			on error errMsg
				set errorCount to errorCount + 1
				set errorMessages to errorMessages & baseName & ": " & errMsg & return
			end try
		end repeat

		if errorCount is 0 then
			display alert "Upscale Complete" message (processedCount as string) & " video(s) upscaled to 2x resolution (2x width × 2x height)."
		else
			set summaryMessage to (processedCount as string) & " upscaled to 2x resolution, " & (errorCount as string) & " error(s)." & return & return & errorMessages
			display alert "Upscale Complete" message summaryMessage as warning
		end if
	end tell

	return input
end run
