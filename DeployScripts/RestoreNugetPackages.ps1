function NugetRestore-Solution {
    param ([string] $SolutionExecutablePath)
    Start-Job -Name RunNugetCommand -Scriptblock {param($sln)
        & nuget restore "$sln" 2>&1 | Out-Null
        write-output $lastExitCode
    } -Arg "$SolutionExecutablePath" | Out-Null
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job 

    return $ErrorLevel
}

$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $ErrorLevel = NugetRestore-Solution $SolutionFile.FullName
    
    if ($ErrorLevel -ne 0) { 
        write-output "exiting with error "$ErrorLevel
        throw $ErrorLevel
    }

}
