on aliasEntry(aliasName, strategy, appNames)
	return {aliasName, strategy, appNames}
end aliasEntry

on appRegistry()
	return {¬
		my aliasEntry("chrome", "chromium", {"Google Chrome", "Google Chrome Canary", "Chromium"}), ¬
		my aliasEntry("chromium", "chromium", {"Chromium", "Google Chrome", "Google Chrome Canary"}), ¬
		my aliasEntry("safari", "safari", {"Safari"}), ¬
		my aliasEntry("firefox", "position", {"Firefox"}), ¬
		my aliasEntry("arc", "chromium", {"Arc"}), ¬
		my aliasEntry("brave", "chromium", {"Brave Browser"}), ¬
		my aliasEntry("edge", "chromium", {"Microsoft Edge"}), ¬
		my aliasEntry("orion", "chromium", {"Orion"}), ¬
		my aliasEntry("vivaldi", "chromium", {"Vivaldi"}), ¬
		my aliasEntry("browser", "browser", {"Google Chrome", "Safari", "Firefox", "Arc", "Brave Browser", "Microsoft Edge", "Chromium", "Orion", "Vivaldi", "Google Chrome Canary"}), ¬
		my aliasEntry("finder", "finder", {"Finder"}), ¬
		my aliasEntry("code", "position", {"Code", "Code - Insiders", "Cursor", "VSCodium", "Visual Studio Code"}), ¬
		my aliasEntry("vscode", "position", {"Code", "Code - Insiders", "Cursor", "VSCodium", "Visual Studio Code"}), ¬
		my aliasEntry("cursor", "position", {"Cursor", "Code", "Code - Insiders", "VSCodium"}), ¬
		my aliasEntry("terminal", "position", {"Terminal", "iTerm2", "Warp", "Alacritty", "kitty", "WezTerm", "Hyper"}), ¬
		my aliasEntry("iterm", "position", {"iTerm2"}), ¬
		my aliasEntry("warp", "position", {"Warp"}), ¬
		my aliasEntry("kitty", "position", {"kitty"}), ¬
		my aliasEntry("alacritty", "position", {"Alacritty"}), ¬
		my aliasEntry("wezterm", "position", {"WezTerm"}), ¬
		my aliasEntry("hyper", "position", {"Hyper"}) ¬
	}
end appRegistry

on normalizeAlias(rawAlias)
	return do shell script "printf '%s' " & quoted form of rawAlias & " | tr '[:upper:]' '[:lower:]'"
end normalizeAlias

on lookupAlias(rawAlias)
	set aliasKey to my normalizeAlias(rawAlias)
	repeat with entry in my appRegistry()
		if item 1 of entry is aliasKey then return entry
	end repeat
	return missing value
end lookupAlias

on findRunningApp(appNames)
	repeat with appName in appNames
		if application (contents of appName) is running then
			return contents of appName
		end if
	end repeat
	return ""
end findRunningApp

on strategyForAppName(appName)
	if appName is "Safari" then return "safari"
	if appName is "Finder" then return "finder"
	if appName is in {"Google Chrome", "Google Chrome Canary", "Chromium", "Arc", "Brave Browser", "Microsoft Edge", "Orion", "Vivaldi"} then return "chromium"
	return "position"
end strategyForAppName

on resolveTarget(rawAlias)
	set entry to my lookupAlias(rawAlias)
	if entry is not missing value then
		set strategy to item 2 of entry
		set appName to my findRunningApp(item 3 of entry)
		if appName is "" then return {"", strategy, rawAlias}
		if strategy is "browser" then set strategy to my strategyForAppName(appName)
		return {appName, strategy, rawAlias}
	end if

	set directName to my findRunningApp({rawAlias})
	if directName is not "" then
		return {directName, my strategyForAppName(directName), rawAlias}
	end if

	set titleName to do shell script "python3 -c " & quoted form of ("print(" & quoted form of rawAlias & ".title())")
	set titleMatch to my findRunningApp({titleName})
	if titleMatch is not "" then
		return {titleMatch, my strategyForAppName(titleMatch), rawAlias}
	end if

	return {"", "", rawAlias}
end resolveTarget

on mergeChromiumWindows(appName)
	tell application appName
		using terms from application "Google Chrome"
			set winCount to count of windows
			if winCount is less than 2 then return {winCount, 0}

			set mergedTabs to 0
			set targetWindow to window 1

			repeat with w from winCount to 2 by -1
				set sourceWindow to window w
				set tabCount to count of tabs of sourceWindow
				repeat with t from tabCount to 1 by -1
					move tab t of sourceWindow to targetWindow
					set mergedTabs to mergedTabs + 1
				end repeat
				close sourceWindow
			end repeat

			return {1, mergedTabs}
		end using terms from
	end tell
end mergeChromiumWindows

on mergeSafariWindows()
	tell application "Safari"
		set winCount to count of windows
		if winCount is less than 2 then return {winCount, 0}

		set mergedTabs to 0
		repeat with w from winCount to 2 by -1
			set tabCount to count of tabs of window w
			repeat with t from tabCount to 1 by -1
				move tab t of window w to window 1
				set mergedTabs to mergedTabs + 1
			end repeat
			close window w
		end repeat

		return {1, mergedTabs}
	end tell
end mergeSafariWindows

on mergeFinderWindows()
	tell application "Finder" to activate
	delay 0.15

	set beforeCount to 0
	try
		tell application "Finder" to set beforeCount to count of Finder windows
	end try

	if beforeCount is less than 2 then return {beforeCount, 0}

	tell application "System Events"
		tell process "Finder"
			set frontmost to true
			click menu item "Merge All Windows" of menu "Window" of menu bar 1
		end tell
	end tell

	delay 0.2

	set afterCount to beforeCount
	try
		tell application "Finder" to set afterCount to count of Finder windows
	end try

	return {afterCount, beforeCount - afterCount}
end mergeFinderWindows

on sweepPositionWindows(procName, targetX, targetY, screenWidth, screenHeight, edgeMargin)
	tell application "System Events"
		tell process procName
			set stdWindows to every window whose subrole is "AXStandardWindow"
			set winCount to count of stdWindows
			if winCount is 0 then return {0, 0}

			repeat with w in stdWindows
				try
					if value of attribute "AXMinimized" of w is true then
						set value of attribute "AXMinimized" of w to false
					end if
				end try
			end repeat

			set targetW to screenWidth - (edgeMargin * 2)
			set targetH to screenHeight - (edgeMargin * 2)
			set winX to targetX + edgeMargin
			set winY to targetY + edgeMargin

			set mainWindow to item 1 of stdWindows
			set size of mainWindow to {targetW, targetH}
			set position of mainWindow to {winX, winY}

			set tuckedAway to 0
			if winCount > 1 then
				repeat with i from 2 to winCount
					try
						set value of attribute "AXMinimized" of (item i of stdWindows) to true
						set tuckedAway to tuckedAway + 1
					end try
				end repeat
			end if

			return {1, tuckedAway}
		end tell
	end tell
end sweepPositionWindows

on setWindowBounds(appName, strategy, targetX, targetY, screenWidth, screenHeight, edgeMargin)
	set leftEdge to targetX + edgeMargin
	set topEdge to targetY + edgeMargin
	set rightEdge to targetX + screenWidth - edgeMargin
	set bottomEdge to targetY + screenHeight - edgeMargin

	if strategy is in {"chromium", "safari"} then
		tell application appName
			if (count of windows) > 0 then
				set bounds of window 1 to {leftEdge, topEdge, rightEdge, bottomEdge}
				set index of window 1 to 1
			end if
		end tell
	else
		my sweepPositionWindows(appName, targetX, targetY, screenWidth, screenHeight, edgeMargin)
	end if

	tell application appName to activate
end setWindowBounds

on sweepApp(appName, strategy, targetX, targetY, screenWidth, screenHeight, edgeMargin)
	set mergeResult to {1, 0}

	if strategy is "chromium" then
		set mergeResult to my mergeChromiumWindows(appName)
	else if strategy is "safari" then
		set mergeResult to my mergeSafariWindows()
	else if strategy is "finder" then
		set mergeResult to my mergeFinderWindows()
	else
		set mergeResult to my sweepPositionWindows(appName, targetX, targetY, screenWidth, screenHeight, edgeMargin)
		return mergeResult
	end if

	my setWindowBounds(appName, strategy, targetX, targetY, screenWidth, screenHeight, edgeMargin)
	return mergeResult
end sweepApp

on formatSummary(aliasLabel, appName, strategy, mergeResult)
	set finalWindows to item 1 of mergeResult
	set mergedCount to item 2 of mergeResult

	if strategy is "position" and mergedCount > 0 then
		return aliasLabel & ": 1 window on display, " & mergedCount & " minimized (" & appName & ")"
	end if

	if strategy is "finder" and mergedCount > 0 then
		return aliasLabel & ": merged " & mergedCount & " windows into " & finalWindows & " on display (" & appName & ")"
	end if

	if mergedCount > 0 then
		return aliasLabel & ": merged " & mergedCount & " tabs into 1 window on display (" & appName & ")"
	end if

	return aliasLabel & ": 1 window on display (" & appName & ")"
end formatSummary

on run argv
	set rawAlias to item 1 of argv
	set targetX to item 2 of argv as integer
	set targetY to item 3 of argv as integer
	set screenWidth to item 4 of argv as integer
	set screenHeight to item 5 of argv as integer

	set edgeMargin to 24
	set aliasLabel to my normalizeAlias(rawAlias)

	set targetInfo to my resolveTarget(rawAlias)
	set appName to item 1 of targetInfo
	set strategy to item 2 of targetInfo

	if appName is "" then
		return aliasLabel & " not running"
	end if

	set mergeResult to my sweepApp(appName, strategy, targetX, targetY, screenWidth, screenHeight, edgeMargin)
	return my formatSummary(aliasLabel, appName, strategy, mergeResult)
end run