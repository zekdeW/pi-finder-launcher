-- pi-launcher.applescript — 访达工具栏按钮：在当前目录运行 pi
--
-- 行为:
--   * 工具栏点击且无选中项  → 取访达最前窗口的文件夹
--   * 点击时有选中项/拖放   → 文件夹用其本身，文件用其所在目录
--   * 没有访达窗口          → 回退到主目录
--   * 打开 Terminal.app 新窗口: cd <目录> && pi（不加 exit，pi 退出后 shell 保留）
--
-- 改用 iTerm2: 把 launchPi 的 tell 块换成:
--     tell application "iTerm"
--         activate
--         tell current window to create window with default profile
--         tell current session of current window to write text "cd " & quoted form of thePath & " && pi"
--     end tell

on run
	set targetPath to missing value
	try
		tell application "Finder"
			if (count of Finder windows) > 0 then
				set targetPath to POSIX path of ((target of front Finder window) as alias)
			end if
		end tell
	end try
	if targetPath is missing value then
		set targetPath to POSIX path of (path to home folder)
	end if
	launchPi(targetPath)
end run

on open theItems
	set p to POSIX path of (item 1 of theItems)
	set targetPath to do shell script "test -d " & quoted form of p & " && printf %s " & quoted form of p & " || dirname " & quoted form of p
	launchPi(targetPath)
end open

on launchPi(thePath)
	tell application "Terminal"
		activate
		do script "cd " & quoted form of thePath & " && pi"
	end tell
end launchPi
