on appGroup(procName)
	set vscodeApps to {"Code", "Code - Insiders", "Cursor", "VSCodium", "Visual Studio Code"}
	set browserApps to {"Google Chrome", "Safari", "Firefox", "Arc", "Brave Browser", "Microsoft Edge", "Chromium", "Orion", "Vivaldi"}
	set terminalApps to {"Terminal", "iTerm2", "Warp", "Alacritty", "kitty", "WezTerm", "Hyper"}

	if vscodeApps contains procName then return "vscode"
	if browserApps contains procName then return "browser"
	if terminalApps contains procName then return "terminal"

	if procName contains "Chrome" or procName contains "Firefox" or procName contains "Safari" or procName contains "Arc" or procName contains "Edge" or procName contains "Brave" or procName contains "Orion" or procName contains "Vivaldi" then return "browser"
	if procName contains "iTerm" or procName contains "Terminal" or procName contains "Warp" or procName contains "Alacritty" or procName contains "kitty" or procName contains "WezTerm" then return "terminal"
	if procName contains "Code" or procName contains "Cursor" or procName contains "VSCodium" then return "vscode"

	return ""
end appGroup

on gridForCount(n)
	if n is less than or equal to 1 then return {1, 1}
	if n is less than or equal to 3 then return {n, 1}
	if n is less than or equal to 6 then return {3, 2}
	if n is less than or equal to 12 then return {4, 3}
	if n is less than or equal to 24 then return {4, 6}
	return {4, 12}
end gridForCount

on tileWindows(winList, screenX, screenY, screenW, screenH)
	set n to count of winList
	if n is 0 then return

	set margin to 8
	set gap to 4
	set gridDims to my gridForCount(n)
	set cols to item 1 of gridDims
	set rows to item 2 of gridDims
	set availW to screenW - (margin * 2)
	set availH to screenH - (margin * 2)
	set cellW to availW div cols
	set cellH to availH div rows

	set i to 0
	repeat with w in winList
		set i to i + 1
		set idx to i - 1
		set col to idx mod cols
		set row to idx div cols
		set winX to screenX + margin + (col * cellW)
		set winY to screenY + margin + (row * cellH)
		set winW to cellW - gap
		set winH to cellH - gap

		tell application "System Events"
			set size of w to {winW, winH}
			set position of w to {winX, winY}
		end tell
	end repeat
end tileWindows

on joinList(theList, maxItems)
	set out to ""
	set limit to maxItems
	if (count of theList) < limit then set limit to count of theList
	repeat with i from 1 to limit
		if i > 1 then set out to out & ", "
		set out to out & item i of theList
	end repeat
	return out
end joinList

on run
	set layoutRotation to (system attribute "SETUP_ROTATION") as integer
	set vscodeX to (system attribute "SETUP_VSCODE_X") as integer
	set vscodeY to (system attribute "SETUP_VSCODE_Y") as integer
	set vscodeW to (system attribute "SETUP_VSCODE_W") as integer
	set vscodeH to (system attribute "SETUP_VSCODE_H") as integer
	set browserX to (system attribute "SETUP_BROWSER_X") as integer
	set browserY to (system attribute "SETUP_BROWSER_Y") as integer
	set browserW to (system attribute "SETUP_BROWSER_W") as integer
	set browserH to (system attribute "SETUP_BROWSER_H") as integer
	set terminalX to (system attribute "SETUP_TERMINAL_X") as integer
	set terminalY to (system attribute "SETUP_TERMINAL_Y") as integer
	set terminalW to (system attribute "SETUP_TERMINAL_W") as integer
	set terminalH to (system attribute "SETUP_TERMINAL_H") as integer
	set vscodeDisplay to (system attribute "SETUP_VSCODE_DISPLAY") as integer
	set browserDisplay to (system attribute "SETUP_BROWSER_DISPLAY") as integer
	set terminalDisplay to (system attribute "SETUP_TERMINAL_DISPLAY") as integer
	set debugMode to (system attribute "SETUP_DEBUG") is "1"

	set vscodeWins to {}
	set browserWins to {}
	set terminalWins to {}
	set seenApps to {}

	tell application "System Events"
		repeat with proc in (every application process)
			try
				set procName to name of proc
				set end of seenApps to procName
				set grp to my appGroup(procName)
				if grp is not equal to "" then
					repeat with w in (every window of proc whose subrole is "AXStandardWindow")
						try
							if value of attribute "AXMinimized" of w is false then
								if grp is "vscode" then
									set end of vscodeWins to w
								else if grp is "browser" then
									set end of browserWins to w
								else if grp is "terminal" then
									set end of terminalWins to w
								end if
							end if
						end try
					end repeat
				end if
			end try
		end repeat
	end tell

	my tileWindows(vscodeWins, vscodeX, vscodeY, vscodeW, vscodeH)
	my tileWindows(browserWins, browserX, browserY, browserW, browserH)
	my tileWindows(terminalWins, terminalX, terminalY, terminalW, terminalH)

	set summary to "rotation " & layoutRotation & " | VS Code -> display " & vscodeDisplay & ", Browsers -> display " & browserDisplay & ", Terminals -> display " & terminalDisplay & " | tiled: vscode=" & (count of vscodeWins) & ", browser=" & (count of browserWins) & ", terminal=" & (count of terminalWins)

	if (count of vscodeWins) + (count of browserWins) + (count of terminalWins) is 0 then
		set summary to summary & " | hint: enable Accessibility for your terminal (System Settings > Privacy and Security > Accessibility)"
		if debugMode then set summary to summary & " | apps: " & my joinList(seenApps, 15)
	end if

	return summary
end run