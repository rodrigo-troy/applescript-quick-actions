on run {input, parameters}
	-- Merge MP4 Videos using FFmpeg (sorted by creation date, with audio, interpolated)

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select some MP4 files in Finder first." buttons {"OK"} default button 1 with icon caution
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
			display dialog "No MP4 files selected. Please select MP4 files to merge." buttons {"OK"} default button 1 with icon caution
			return
		end if

		if (count of mp4Files) < 2 then
			display dialog "Please select at least 2 MP4 files to merge." buttons {"OK"} default button 1 with icon caution
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

		set sourceFile to item 1 of mp4Files as alias
		set parentFolder to container of sourceFile as alias
		set parentFolderPath to POSIX path of parentFolder
		set sourceName to name of sourceFile
		set baseName to text 1 thru -5 of sourceName

		set fileListPath to do shell script "mktemp -t ffmpeg_concat_list"
		set fileListContent to ""

		set quotedPaths to ""
		repeat with f in mp4Files
			set quotedPaths to quotedPaths & " " & quoted form of (POSIX path of (f as alias))
		end repeat
		set sortedString to do shell script "stat -f '%B %N' " & quotedPaths & " | sort -n | cut -d' ' -f2-"

		repeat with filePath in paragraphs of sortedString
			if length of filePath > 0 then
				set escapedPath to my replaceText(filePath as string, "'", "'\\''")
				set fileListContent to fileListContent & "file '" & escapedPath & "'" & linefeed
			end if
		end repeat

		do shell script "echo " & quoted form of fileListContent & " > " & quoted form of fileListPath

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set outputName to baseName & "-merged_" & timestamp & ".mp4"
		set outputPath to parentFolderPath & outputName

		set ffmpegCmd to ffmpegPath & " -y -f concat -safe 0 -i " & quoted form of fileListPath & " -vf \"minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1\" -c:v h264_videotoolbox -b:v 10M -c:a aac -b:a 192k " & quoted form of outputPath & " 2>&1"

		try
			display notification "Processing... this may take a while" with title "Merging Videos"
			do shell script ffmpegCmd
			display notification "Created: " & outputName with title "Merge Complete" subtitle ((count of mp4Files) as string) & " files merged + interpolated"
		on error errMsg
			display dialog "Error merging files:" & return & return & errMsg buttons {"OK"} default button 1 with icon stop
		end try

		do shell script "rm -f " & quoted form of fileListPath
	end tell

	return input
end run

on replaceText(this_text, search_string, replacement_string)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to oldDelims
	return this_text
end replaceText
