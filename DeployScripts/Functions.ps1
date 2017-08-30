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


function Get-DeploymentPath {
    param([object] $root
        , [string] $fullPath = "")

        if ($root.FullName -eq $MainSolutionDir -or "$MainSolutionDir" -eq "$($root.FullName)\." -or $root.parent.name -eq $null) {
            Write-Output $fullPath
            return
        }
        if ($fullPath) {
            $fullPath = "\$fullPath"
        }
        Get-DeploymentPath $root.parent "$($root.Name)$fullPath"
}