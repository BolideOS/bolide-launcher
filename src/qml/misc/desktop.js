.pragma library
var panelsGrid
var appLauncher
var desktop
var launchTimestamp = 0
var launchAppName = ""

// Cached app windows by title (hidden but alive)
var cachedWindows = {}
var cachedTimestamps = {}
var raiseAppFunc = null

