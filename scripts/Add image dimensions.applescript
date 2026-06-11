on run {input, parameters}
	if (count of input) = 0 then
		display dialog "No items selected" buttons {"OK"} default button 1 with icon caution
		return
	end if

	set totalRenamed to 0
	set totalSkipped to 0
	set foldersProcessed to {}
	set filesProcessed to 0

	repeat with inputItem in input
		tell application "Finder"
			set itemAlias to inputItem as alias
			if class of (item itemAlias) is folder then
				set folderRef to itemAlias
				set imageFiles to every file of folderRef
				set totalFiles to count of imageFiles

				if totalFiles = 0 then
					display alert "Image Dimensions - Processing End" message "No files to process" buttons {"OK"} default button "OK"
					display notification "No files to process" with title "Processing End" sound name "Glass"
				else
					repeat with imageFile in imageFiles
						set fileResult to my processImageFile(imageFile)
						if fileResult is "renamed" then
							set totalRenamed to totalRenamed + 1
						else
							set totalSkipped to totalSkipped + 1
						end if
					end repeat

					set end of foldersProcessed to (name of folderRef)
				end if
			else
				set fileRef to item itemAlias
				set fileResult to my processImageFile(fileRef)
				if fileResult is "renamed" then
					set totalRenamed to totalRenamed + 1
				else
					set totalSkipped to totalSkipped + 1
				end if
				set filesProcessed to filesProcessed + 1
			end if
		end tell
	end repeat

	set folderCount to count of foldersProcessed
	if folderCount = 0 and filesProcessed > 0 then
		set folderText to "Processed " & filesProcessed & " files"
	else if folderCount = 1 and filesProcessed = 0 then
		set folderText to "Folder: " & (item 1 of foldersProcessed)
	else if folderCount > 0 and filesProcessed = 0 then
		set folderText to "Processed " & folderCount & " folders"
	else
		set folderText to "Processed " & folderCount & " folders, " & filesProcessed & " files"
	end if

	set summaryText to folderText & return & return
	set summaryText to summaryText & "✓ Renamed: " & totalRenamed & " images" & return
	set summaryText to summaryText & "⊘ Skipped: " & totalSkipped & " files" & return
	set summaryText to summaryText & "━━━━━━━━━━━━━━━━" & return
	set summaryText to summaryText & "Total: " & (totalRenamed + totalSkipped) & " files processed"

	display alert "✅ Image Dimensions Added" message summaryText buttons {"OK"} default button "OK"

	return input
end run

on processImageFile(imageFile)
	try
		tell application "Finder"
			set fileName to name of imageFile
			set fileExt to name extension of imageFile
		end tell

		if fileExt is not in {"jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "bmp", "tiff", "tif"} then
			return "skipped"
		end if

		set posixPath to POSIX path of (imageFile as alias)

		try
			set sipsOutput to do shell script "sips -g pixelWidth -g pixelHeight " & quoted form of posixPath
			set imgWidth to my extractSipsValue(sipsOutput, "pixelWidth")
			set imgHeight to my extractSipsValue(sipsOutput, "pixelHeight")
		on error
			return "skipped"
		end try

		set baseName to text 1 thru -((length of fileExt) + 2) of fileName
		set dimensionTag to "-" & imgWidth & "w-" & imgHeight & "h"

		if fileName contains dimensionTag then
			return "skipped"
		end if

		set newName to baseName & dimensionTag & "." & fileExt
		tell application "Finder" to set name of imageFile to newName
		return "renamed"
	on error
		return "skipped"
	end try
end processImageFile

on extractSipsValue(sipsOutput, sipsKey)
	repeat with paraRef in paragraphs of sipsOutput
		set paraStr to paraRef as string
		if paraStr contains (sipsKey & ":") then
			return last word of paraStr
		end if
	end repeat
	error "extractSipsValue: key '" & sipsKey & "' not found in sips output"
end extractSipsValue