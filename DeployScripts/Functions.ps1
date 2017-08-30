$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$DeployScriptsDirectory = "$MainSolutionDir\DeployScripts"

function RunScript {
    param([string] $ScriptName)
    try {
        & "$DeployScriptsDirectory\$ScriptName.ps1"
        $errorLevel = 0
    } catch {
        write-output $_
        $errorLevel = 1
    }
    if ($errorLevel -ne 0) {
        Write-Output "Error while Running $ScriptName"
        throw $errorLevel
    }
    
}