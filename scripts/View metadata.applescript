on run {input, parameters}
	-- Write a human-readable metadata dump for each Finder-selected video or
	-- image file to a .txt sidecar in the same folder. Conceptual pair to
	-- Remove metadata.applescript: anything that script strips, this script
	-- can show you before you strip it.

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select video or image files in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set exifPath to ""
		set possibleExifPaths to {"/opt/homebrew/bin/exiftool", "/usr/local/bin/exiftool", "/usr/bin/exiftool"}

		repeat with testPath in possibleExifPaths
			try
				do shell script "test -x " & testPath
				set exifPath to testPath as string
				exit repeat
			end try
		end repeat

		if exifPath is "" then
			display dialog "ExifTool not found. Install it:" & return & return & "    brew install exiftool" buttons {"OK"} default button 1 with icon stop
			return
		end if

		set supportedExtensions to {"mp4", "mov", "jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "bmp", "tiff", "tif"}
		set supportedFiles to {}
		set skippedCount to 0

		repeat with f in selectedFiles
			if (name extension of f as string) is in supportedExtensions then
				set end of supportedFiles to f
			else
				set skippedCount to skippedCount + 1
			end if
		end repeat

		if supportedFiles is {} then
			display dialog "No supported files selected." & return & return & "Videos: .mp4, .mov" & return & "Images: .jpg, .jpeg, .png, .gif, .heic, .heif, .webp, .bmp, .tiff, .tif" buttons {"OK"} default button 1 with icon caution
			return
		end if

		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set humanTimestamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
		set processedCount to 0
		set errorList to {}
		set outputFolderName to ""
		set totalToProcess to count of supportedFiles
		display notification ("Processing " & totalToProcess & " file(s)...") with title "Reading Metadata"

		repeat with sf in supportedFiles
			try
				set vFile to sf as alias
				set vName to name of vFile
				set vParent to container of vFile as alias
				set vParentPath to POSIX path of vParent
				set vSourcePath to POSIX path of vFile
				set vBaseName to my stripExtension(vName)
				set vOutputName to vBaseName & "-metadata_" & timestamp & ".txt"
				set vOutputPath to vParentPath & vOutputName
				if outputFolderName is "" then set outputFolderName to (name of vParent as string)

				set exCmd to "{ printf '# Metadata for: %s\\n# Source: %s\\n# Generated: %s\\n\\n' " & quoted form of vName & " " & quoted form of vSourcePath & " " & quoted form of humanTimestamp & "; " & exifPath & " -G1 -a -s " & quoted form of vSourcePath & "; } > " & quoted form of vOutputPath & " 2>&1"
				do shell script exCmd
				set processedCount to processedCount + 1
				display notification "Read " & (processedCount as string) & " of " & (totalToProcess as string) with title "Reading Metadata"
			on error errMsg
				set end of errorList to (name of sf as string) & ": " & errMsg
			end try
		end repeat

		set errorCount to count of errorList
		set summaryMsg to "Processed: " & processedCount & return & "Errors: " & errorCount & return & "Skipped: " & skippedCount

		if outputFolderName is not "" then
			set summaryMsg to summaryMsg & return & return & "Output folder: " & outputFolderName
		end if

		if errorCount > 0 then
			set summaryMsg to summaryMsg & return & return & "Errors:" & return
			repeat with e in errorList
				set summaryMsg to summaryMsg & "  • " & (e as string) & return
			end repeat
			display alert "Metadata Viewed" message summaryMsg as warning
		else
			display alert "Metadata Viewed" message summaryMsg
		end if

	end tell

	return input
end run

on stripExtension(fileName)
	set AppleScript's text item delimiters to "."
	set tokens to text items of fileName
	if (count of tokens) = 1 then
		set AppleScript's text item delimiters to ""
		return fileName
	end if
	set baseName to (items 1 thru -2 of tokens) as string
	set AppleScript's text item delimiters to ""
	return baseName
end stripExtension

on fileExtension(fileName)
	set AppleScript's text item delimiters to "."
	set tokens to text items of fileName
	if (count of tokens) = 1 then
		set AppleScript's text item delimiters to ""
		return ""
	end if
	set ext to "." & last item of tokens
	set AppleScript's text item delimiters to ""
	return ext
end fileExtension
