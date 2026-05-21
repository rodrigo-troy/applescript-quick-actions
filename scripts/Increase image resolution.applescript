on run {input, parameters}
	-- Upscale selected images by 3x using Pixelmator Pro's ML Super Resolution.
	-- Prompts for output format (PNG/JPEG/HEIC).

	set supportedExtensions to {"pxd", "heic", "jpg", "jpeg", "jp2", "pdf", "png", "tif", "tiff", "webp", "gif"}

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
		display dialog "No supported image files selected." & return & return & "Supported formats: PXD, HEIC, JPEG, JPEG 2000, PDF (single page), PNG, TIFF, WebP, GIF" buttons {"OK"} default button 1 with icon caution
		return
	end if

	set formatChoice to choose from list {"PNG (lossless)", "JPEG (quality 90)", "JPEG (quality 80)", "HEIC (quality 90)"} with prompt "Choose output format:" default items {"PNG (lossless)"} OK button name "Upscale" cancel button name "Cancel"
	if formatChoice is false then return
	set formatLabel to item 1 of formatChoice
	if formatLabel starts with "JPEG" then
		set outFormat to "JPEG"
		set outExt to "jpg"
		if formatLabel contains "80" then
			set outQuality to 80
		else
			set outQuality to 90
		end if
	else if formatLabel starts with "HEIC" then
		set outFormat to "HEIC"
		set outExt to "heic"
	else
		set outFormat to "PNG"
		set outExt to "png"
	end if

	set processedCount to 0
	set errorCount to 0
	set errorMessages to ""
	set totalFiles to count of imageFiles

	display notification "Processing " & totalFiles & " image(s) at 3x..." with title "Super Resolution" sound name "default"

	repeat with i from 1 to totalFiles
		set imgAlias to item i of imageFiles
		set imgPosix to POSIX path of imgAlias
		set pathParts to splitPath(imgPosix)
		set parentDir to item 1 of pathParts
		set nameNoExt to item 2 of pathParts
		set outputPath to parentDir & "/" & nameNoExt & "-3x." & outExt

		set didOpen to false
		try
			tell application "Pixelmator Pro"
				open imgAlias
				set didOpen to true
				super resolution front document

				if outFormat is "PNG" then
					export front document to POSIX file outputPath as PNG
				else if outFormat is "JPEG" then
					export front document to POSIX file outputPath as JPEG with properties {compression factor:outQuality}
				else
					export front document to POSIX file outputPath as HEIC with properties {compression factor:90}
				end if
			end tell
			set processedCount to processedCount + 1
			display notification "Upscaled " & (processedCount as string) & " of " & (totalFiles as string) with title "Super Resolution"
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
		display alert "Super Resolution Complete" message (processedCount as string) & " image(s) upscaled 3x and saved as " & outFormat & "."
	else
		display alert "Super Resolution Complete" message (processedCount as string) & " processed, " & (errorCount as string) & " error(s)." & return & return & errorMessages as warning
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
	else
		set nameNoExt to fileBase
	end if
	set AppleScript's text item delimiters to ""
	return {parentDir, nameNoExt}
end splitPath

on isPixelmatorProInstalled()
	try
		tell application "Finder" to set _appFile to application file id "com.pixelmatorteam.pixelmator.x"
		return true
	on error
		return false
	end try
end isPixelmatorProInstalled
