// Helper function to save config using a simple approach
.pragma library

function saveConfig(configText, scriptPath) {
    // This will be called from QML
    // For now, return the command to execute
    var escaped = configText.replace(/'/g, "'\\''").replace(/\n/g, "\\n")
    return "echo '" + escaped + "' | bash " + scriptPath
}

