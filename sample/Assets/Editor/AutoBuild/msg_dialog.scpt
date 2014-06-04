#!/usr/bin/osascript

on showDialog(msg)
  activate

  tell application "Unity"
    display dialog msg ¬
      with title "Unity iOS Builder" ¬
      with icon note
  end tell
end showDialog

on run argv
  if (count of argv) = 1 then
    set msg to item 1 of argv
  else
    set msg to "メッセージを指定してください。"
  end if

  my showDialog(msg)
end run
