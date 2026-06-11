on run {input, parameters}
	-- Crossfade two MP4 videos into one using FFmpeg's xfade (video) + acrossfade (audio) filters.
	-- The two selected clips are ordered by creation date (older clip plays first), then blended
	-- with a user-chosen crossfade duration (default 1s).

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select two MP4 files in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set mp4Files to {}
		repeat with f in selectedFiles
			set fName to name of f as string
			if fName ends with ".mp4" then
				set end of mp4Files to (f as alias)
			end if
		end repeat
	end tell

	set mp4Count to count of mp4Files
	if mp4Count is not 2 then
		display dialog "Please select exactly two MP4 files to crossfade (you selected " & (mp4Count as string) & ")." buttons {"OK"} default button 1 with icon caution
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

	set posixA to POSIX path of (item 1 of mp4Files)
	set posixB to POSIX path of (item 2 of mp4Files)
	set sortedPaths to do shell script "stat -f '%B %N' " & quoted form of posixA & " " & quoted form of posixB & " | sort -n | cut -d' ' -f2-"
	set clip1Path to paragraph 1 of sortedPaths
	set clip2Path to paragraph 2 of sortedPaths

	set clip1Duration to do shell script ffprobePath & " -v error -show_entries format=duration -of csv=p=0 " & quoted form of clip1Path
	set clip2Duration to do shell script ffprobePath & " -v error -show_entries format=duration -of csv=p=0 " & quoted form of clip2Path
	if clip1Duration is "" or clip1Duration is "N/A" then
		display dialog "Couldn't read the duration of the first clip:" & return & return & clip1Path buttons {"OK"} default button 1 with icon stop
		return
	end if
	if clip2Duration is "" or clip2Duration is "N/A" then
		display dialog "Couldn't read the duration of the second clip:" & return & return & clip2Path buttons {"OK"} default button 1 with icon stop
		return
	end if

	try
		set userResponse to display dialog "Crossfade duration (seconds):" default answer "1" buttons {"Cancel", "OK"} default button "OK" with icon note
	on error number -128
		return
	end try

	set cfRaw to text returned of userResponse
	set AppleScript's text item delimiters to ","
	set cfParts to text items of cfRaw
	set AppleScript's text item delimiters to "."
	set cfNormalized to cfParts as text
	set AppleScript's text item delimiters to ""

	set offsetCmd to "LC_ALL=C awk -v cf=" & quoted form of cfNormalized & " -v dur=" & quoted form of clip1Duration & " -v dur2=" & quoted form of clip2Duration & " 'BEGIN{ if (cf !~ /^[0-9]*[.]?[0-9]+$/) { print \"ERR_NOTNUM\"; exit } if (cf+0 <= 0) { print \"ERR_NOTPOS\"; exit } if (dur !~ /^[0-9]*[.]?[0-9]+$/ || dur+0 <= 0) { print \"ERR_DUR\"; exit } if (dur2 !~ /^[0-9]*[.]?[0-9]+$/ || dur2+0 <= 0) { print \"ERR_DUR\"; exit } if (cf+0 >= dur+0) { print \"ERR_TOOLONG\"; exit } if (cf+0 >= dur2+0) { print \"ERR_TOOLONG2\"; exit } printf \"%.6f\", dur-cf }'"
	set offsetValue to do shell script offsetCmd

	if offsetValue is "ERR_NOTNUM" then
		display dialog "Crossfade duration must be a number (e.g. 1 or 0.5)." buttons {"OK"} default button 1 with icon caution
		return
	else if offsetValue is "ERR_NOTPOS" then
		display dialog "Crossfade duration must be greater than 0." buttons {"OK"} default button 1 with icon caution
		return
	else if offsetValue is "ERR_DUR" then
		display dialog "Couldn't read a valid duration for the first clip." buttons {"OK"} default button 1 with icon stop
		return
	else if offsetValue is "ERR_TOOLONG" then
		display dialog "Crossfade duration must be shorter than the first clip (" & clip1Duration & "s)." buttons {"OK"} default button 1 with icon caution
		return
	else if offsetValue is "ERR_TOOLONG2" then
		display dialog "Crossfade duration must be shorter than the second clip (" & clip2Duration & "s)." buttons {"OK"} default button 1 with icon caution
		return
	end if

	set timestamp to do shell script "date +%Y%m%d_%H%M%S"
	set AppleScript's text item delimiters to "/"
	set clip1Parts to text items of clip1Path
	set clip1FileName to last item of clip1Parts
	set parentDirPath to (items 1 thru -2 of clip1Parts) as text
	set AppleScript's text item delimiters to ""
	set baseName to text 1 thru -5 of clip1FileName
	set outputName to baseName & "-crossfaded_" & timestamp & ".mp4"
	set outputPath to parentDirPath & "/" & outputName

	set filterComplex to "[0:v][1:v]xfade=transition=fade:duration=" & cfNormalized & ":offset=" & offsetValue & "[v];[0:a][1:a]acrossfade=d=" & cfNormalized & ":c1=tri:c2=tri[a]"
	set ffmpegCmd to ffmpegPath & " -y -i " & quoted form of clip1Path & " -i " & quoted form of clip2Path & " -filter_complex \"" & filterComplex & "\" -map \"[v]\" -map \"[a]\" -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 128k " & quoted form of outputPath & " 2>&1"

	try
		display notification "Crossfading… this may take a moment" with title "Crossfade Videos"
		do shell script ffmpegCmd
		display notification "Created: " & outputName with title "Crossfade Complete"
	on error errMsg
		display dialog "Error crossfading videos:" & return & return & errMsg buttons {"OK"} default button 1 with icon stop
	end try

	return input
end run
