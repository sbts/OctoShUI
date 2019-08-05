# OctoShUI
Octoprint bash Text User Interface (TUI)

OctoShUI.sh [ --no-clear ]

This script provides a Text UI for Octoprint
It depends on the octoprint_statfs plugin
    https://github.com/sbts/OctoPrint_StatFS.git

The UI is "status only" at the moment
  ie: you can't control anything

The UI is designed to run on a standard Pi 7" touchscreen
- @ 100 Columns by 30 Lines
Other display sizes are possible, but the two Output functions
would need to be carefully adjusted
- ReDraw
- GetData
