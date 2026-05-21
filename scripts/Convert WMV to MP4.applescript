on run {input, parameters}
	-- Convert a single WMV file to MP4 using FFmpeg (hardware-accelerated H.264 encoding)

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select a WMV file in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set wmvFiles to {}
		repeat with f in selectedFiles
			set fName to name of f as string
			if fName ends with ".wmv" then
				set end of wmvFiles to f
			end if
		end repeat

		if wmvFiles is {} then
			display dialog "No WMV file selected. Please select a WMV file to convert." buttons {"OK"} default button 1 with icon caution
			return
		end if

		if (count of wmvFiles) > 1 then
			display dialog "Please select only 1 WMV file." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set sourceFile to item 1 of wmvFiles as alias
		set parentFolder to container of sourceFile as alias
		set parentFolderPath to POSIX path of parentFolder
		set sourcePath to POSIX path of sourceFile

		set sourceName to name of sourceFile
		set baseName to text 1 thru -5 of sourceName
		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set outputName to baseName & "-converted_" & timestamp & ".mp4"
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

		set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -c:v h264_videotoolbox -q:v " & videoQuality & " -c:a aac -b:a " & audioBitrate & " " & quoted form of outputPath & " 2>&1"

		try
			display notification "Converting WMV to MP4... this may take a while" with title "Converting Video"
			do shell script ffmpegCmd
			display notification "Created: " & outputName with title "Conversion Complete" subtitle "WMV converted to MP4"
		on error errMsg
			display dialog "Error converting file:" & return & return & errMsg buttons {"OK"} default button 1 with icon stop
		end try

	end tell

	return input
end run
