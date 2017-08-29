$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $SolutionFileExecutablePath = $SolutionFile.FullName
    #Start-Job -Name RunNugetCommand -Scriptblock {param($SolutionFileExecutablePath)
        & nuget restore "$SolutionFileExecutablePath" 2>&1 | Out-Null
     #   write-output $lastExitCode
     $ErrorLevel = $lastExitCode
    #} -Arg "$SolutionFileExecutablePath"
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job

    write-output "Recieving Job"
    write-output $ErrorLevel
    if ($ErrorLevel -ne 0) { 
        write-output "exiting with error "$ErrorLevel
        throw $ErrorLevel
    }

}
