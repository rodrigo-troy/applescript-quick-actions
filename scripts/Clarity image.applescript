on run {input, parameters}
	-- Apply Pixelmator Pro's clarity adjustment at intensity 20 (20% of the 0–100 slider)
	-- to each selected image. Saves a new file alongside the original with a "-sharpened"
	-- suffix in the source format. Original file is not modified.
	-- Quits Pixelmator Pro at the end if it wasn't already running when the script started.

	set supportedExtensions to {"heic", "jpg", "jpeg", "jp2", "png", "tif", "tiff", "webp", "gif"}

	if not isPixelmatorProInstalled() then
		display dialog "Pixelmator Pro is not installed." & return & return & "Install it from the Mac App Store or pixelmator.com/pro." buttons {"OK"} default button 1 with icon stop
		return
	end if

	tell application "System Events"
		set wasRunning to (exists (processes where name is "Pixelmator Pro"))
	end tell

	tell application "Finder"
		set selectedFiles to selection

		if selectedFiles is {} then
			display dialog "Please select image files in Finder first." buttons {"OK"} default button 1 with icon caution
			return
		end if

		set imageFiles to {}
		repeat with f in selectedFiles
			if (name extension of f as string) is in supportedExtensions then
				set end of imageFiles to (f as alias)
			end if
		end repeat
	end tell

	if imageFiles is {} then
		display dialog "No supported image files selected." & return & return & "Supported formats: HEIC, JPEG, JPEG 2000, PNG, TIFF, WebP, GIF" buttons {"OK"} default button 1 with icon caution
		return
	end if

	set processedCount to 0
	set errorCount to 0
	set errorMessages to ""
	set totalFiles to count of imageFiles

	display notification "Sharpening " & totalFiles & " image(s)..." with title "Sharpen" sound name "default"

	repeat with i from 1 to totalFiles
		set imgAlias to item i of imageFiles
		set imgPosix to POSIX path of imgAlias
		set pathParts to splitPath(imgPosix)
		set parentDir to item 1 of pathParts
		set nameNoExt to item 2 of pathParts
		set inExt to item 3 of pathParts
		set outputPath to parentDir & "/" & nameNoExt & "-sharpened." & inExt

		set didOpen to false
		try
			tell application "Pixelmator Pro"
				open imgAlias
				set didOpen to true
				tell the color adjustments of the first layer of the front document
					set its clarity to 20
				end tell
				if inExt is "jpg" or inExt is "jpeg" then
					export front document to POSIX file outputPath as JPEG with properties {compression factor:90}
				else if inExt is "heic" then
					export front document to POSIX file outputPath as HEIC with properties {compression factor:90}
				else if inExt is "png" then
					export front document to POSIX file outputPath as PNG
				else if inExt is "tif" or inExt is "tiff" then
					export front document to POSIX file outputPath as TIFF
				else if inExt is "webp" then
					export front document to POSIX file outputPath as WebP with properties {compression factor:90}
				else if inExt is "gif" then
					export front document to POSIX file outputPath as GIF
				else if inExt is "jp2" then
					export front document to POSIX file outputPath as JPEG2000 with properties {compression factor:90}
				end if
			end tell
			set processedCount to processedCount + 1
			display notification "Sharpened " & (processedCount as string) & " of " & (totalFiles as string) with title "Sharpen"
		on error errMsg
			set errorCount to errorCount + 1
			set errorMessages to errorMessages & nameNoExt & ": " & errMsg & return
		end try

		if didOpen then
			try
				tell application "Pixelmator Pro" to close front document saving no
			end try
		end if
	end repeat

	if errorCount is 0 then
		display alert "Sharpen Complete" message (processedCount as string) & " image(s) sharpened."
	else
		display alert "Sharpen Complete" message (processedCount as string) & " processed, " & (errorCount as string) & " error(s)." & return & return & errorMessages as warning
	end if

	if not wasRunning then
		try
			tell application "Pixelmator Pro" to quit
		end try
	end if

	return input
end run

on splitPath(posixPath)
	set AppleScript's text item delimiters to "/"
	set pathItems to text items of posixPath
	set fileBase to last item of pathItems
	set parentDir to (items 1 thru -2 of pathItems) as text
	set AppleScript's text item delimiters to "."
	set nameItems to text items of fileBase
	if (count of nameItems) > 1 then
		set nameNoExt to (items 1 thru -2 of nameItems) as text
		set fileExt to last item of nameItems
	else
		set nameNoExt to fileBase
		set fileExt to ""
	end if
	set AppleScript's text item delimiters to ""
	return {parentDir, nameNoExt, fileExt}
end splitPath

on isPixelmatorProInstalled()
	try
		tell application "Finder" to set _appFile to application file id "com.pixelmatorteam.pixelmator.x"
		return true
	on error
		return false
	end try
end isPixelmatorProInstalled
