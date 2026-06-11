on run {input, parameters}
	-- Interpolate one or more MP4 Videos to a chosen target framerate (30/60 fps)
	-- using FFmpeg with hardware encoding. Prompts once per batch for encoder (H.264 / HEVC)
	-- and target FPS.

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
			display dialog "No MP4 file selected. Please select one or more MP4 files to interpolate." buttons {"OK"} default button 1 with icon caution
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

		set ffprobePath to (text 1 thru -7 of ffmpegPath) & "ffprobe"

		set codecOptions to {"H.264 (universal, 10 Mbps CBR)", "HEVC 10-bit (Apple ecosystem, smaller files)"}
		set codecChoice to choose from list codecOptions default items {"H.264 (universal, 10 Mbps CBR)"} with prompt "Choose encoder:" without multiple selections allowed
		if codecChoice is false then return

		set choiceText to item 1 of codecChoice
		if choiceText starts with "HEVC" then
			set videoFormatSuffix to ",format=p010le"
			set videoCodecArgs to "-c:v hevc_videotoolbox -profile:v main10 -q:v 80 -tag:v hvc1"
			set audioCodecArgs to "-c:a copy"
			set codecLabel to "HEVC"
		else
			set videoFormatSuffix to ""
			set videoCodecArgs to "-c:v h264_videotoolbox -b:v 10M"
			set audioCodecArgs to "-c:a aac -b:a 192k"
			set codecLabel to "H.264"
		end if

		set fpsOptions to {"30 fps", "60 fps (default — standard smooth video)"}
		set fpsChoice to choose from list fpsOptions default items {"60 fps (default — standard smooth video)"} with prompt "Choose target frame rate:" without multiple selections allowed
		if fpsChoice is false then return

		set fpsChoiceText to item 1 of fpsChoice
		if fpsChoiceText starts with "30 fps" then
			set targetFps to 30
		else
			set targetFps to 60
		end if

		set videoFilter to "minterpolate=fps=" & (targetFps as string) & ":mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1" & videoFormatSuffix

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set totalFiles to count of mp4Files
		set processedCount to 0
		set errorCount to 0
		set skippedCount to 0
		set errorMessages to ""

		display notification "Interpolating " & totalFiles & " video(s) to " & (targetFps as string) & "fps (" & codecLabel & ")..." with title "Interpolate MP4 Video"

		repeat with sourceRef in mp4Files
			set sourceFile to sourceRef as alias
			set parentFolder to container of sourceFile as alias
			set parentFolderPath to POSIX path of parentFolder
			set sourcePath to POSIX path of sourceFile

			set sourceName to name of sourceFile
			set baseName to text 1 thru -5 of sourceName
			set outputName to baseName & "-interpolated_" & timestamp & ".mp4"
			set outputPath to parentFolderPath & outputName

			set shouldSkip to false
			try
				set fpsCheckCmd to ffprobePath & " -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 " & quoted form of sourcePath & " | LC_ALL=C awk -F/ -v target=" & (targetFps as string) & " '$2>0 { if ($1/$2 >= target-0.5) print \"SKIP\" }'"
				if (do shell script fpsCheckCmd) is "SKIP" then
					set shouldSkip to true
					set skippedCount to skippedCount + 1
				end if
			end try

			if not shouldSkip then
				set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of sourcePath & " -vf \"" & videoFilter & "\" " & videoCodecArgs & " " & audioCodecArgs & " " & quoted form of outputPath & " 2>&1"

				try
					do shell script ffmpegCmd
					set processedCount to processedCount + 1
					display notification "Interpolated " & (processedCount as string) & " of " & (totalFiles as string) with title "Interpolate MP4 Video"
				on error errMsg
					set errorCount to errorCount + 1
					set errorMessages to errorMessages & baseName & ": " & errMsg & return
				end try
			end if
		end repeat

		if errorCount is 0 and skippedCount is 0 then
			display alert "Interpolation Complete" message (processedCount as string) & " video(s) interpolated to " & (targetFps as string) & "fps (" & codecLabel & ")."
		else
			set summaryMessage to (processedCount as string) & " interpolated to " & (targetFps as string) & "fps (" & codecLabel & ")"
			if skippedCount > 0 then
				set summaryMessage to summaryMessage & ", " & (skippedCount as string) & " skipped (already " & (targetFps as string) & "+fps)"
			end if
			if errorCount > 0 then
				set summaryMessage to summaryMessage & ", " & (errorCount as string) & " error(s)"
			end if
			set summaryMessage to summaryMessage & "."

			if errorCount > 0 then
				set summaryMessage to summaryMessage & return & return & errorMessages
				display alert "Interpolation Complete" message summaryMessage as warning
			else
				display alert "Interpolation Complete" message summaryMessage
			end if
		end if

	end tell

	return input
end run
