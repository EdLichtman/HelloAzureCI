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

function Restore-NugetPackagesOnSolution {
    param ([string] $SolutionExecutablePath)
    Start-Job -Name RunNugetCommand -Scriptblock {param($sln)
        & nuget restore "$sln" 2>&1 | Out-Null
        write-output $lastExitCode
    } -Arg "$SolutionExecutablePath" | Out-Null
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job 

    return $ErrorLevel
}
