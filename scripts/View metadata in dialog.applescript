on run {input, parameters}
	-- Show a scrollable metadata dump for each Finder-selected video or image
	-- file in an on-screen list, writing nothing to disk.

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

		set viewedCount to 0
		set errorList to {}

		repeat with sf in supportedFiles
			try
				set vFile to sf as alias
				set vName to name of vFile
				set vSourcePath to POSIX path of vFile

				set metaText to do shell script exifPath & " -G1 -a -s " & quoted form of vSourcePath
				set metaLines to paragraphs of metaText

				set viewResult to (choose from list metaLines with title "Metadata" with prompt ("Metadata for: " & vName) OK button name "Done" cancel button name "Stop" with multiple selections allowed and empty selection allowed)
				set viewedCount to viewedCount + 1
				if viewResult is false then exit repeat
			on error errMsg
				set end of errorList to (name of sf as string) & ": " & errMsg
			end try
		end repeat

		set errorCount to count of errorList
		if errorCount > 0 or skippedCount > 0 then
			set summaryMsg to "Viewed: " & viewedCount & return & "Errors: " & errorCount & return & "Skipped: " & skippedCount

			if errorCount > 0 then
				set summaryMsg to summaryMsg & return & return & "Errors:" & return
				repeat with e in errorList
					set summaryMsg to summaryMsg & "  • " & (e as string) & return
				end repeat
				display alert "View Metadata in Dialog" message summaryMsg as warning
			else
				display alert "View Metadata in Dialog" message summaryMsg
			end if
		end if
	end tell

	return input
end run
