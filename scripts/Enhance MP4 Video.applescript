on run {input, parameters}
	-- Enhance a single MP4 Video using FFmpeg (interpolated to 60fps with hardware encoding)

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
			display dialog "No MP4 file selected. Please select an MP4 file to enhance." buttons {"OK"} default button 1 with icon caution
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
		set outputName to baseName & "-enhanced_" & timestamp & ".mp4"
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

		set ffprobePath to (text 1 thru -7 of ffmpegPath) & "ffprobe"
		try
			set fpsCheckCmd to ffprobePath & " -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 " & quoted form of sourcePath & " | awk -F/ '$2>0 {print $1/$2}'"
			set sourceFps to (do shell script fpsCheckCmd) as real

			if sourceFps ≥ 59.5 then
				display dialog "Source is already at " & (round sourceFps) & "fps — no interpolation needed, nothing to do." buttons {"OK"} default button 1 with icon note
				return
			end if
		end try

		set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -vf \"minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1\" -c:v h264_videotoolbox -b:v 10M -c:a aac -b:a 192k " & quoted form of outputPath & " 2>&1"

		try
			display notification "Processing... this may take a while" with title "Enhancing Video"
			do shell script ffmpegCmd
			display notification "Created: " & outputName with title "Enhancement Complete" subtitle "Video interpolated to 60fps"
		on error errMsg
			display dialog "Error processing file:" & return & return & errMsg buttons {"OK"} default button 1 with icon stop
		end try

	end tell

	return input
end run
