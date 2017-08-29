$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $SolutionFileExecutablePath = $SolutionFile.FullName
    write-output "& nuget restore $SolutionFileExecutablePath"
    try {
        $NugetRestoreCommand = 'nuget restore "{0}"' -f $SolutionFileExecutablePath
        Start-Process $MainSolutionDir\DeployScripts\RunCommandAsSeparateProcess.cmd $NugetRestoreCommand
    }catch{ 
        try {
            write-output $_.Exception|format-list -force
            } catch {Write-Output "there is a serious glitch in the matrix"}
    }
}
exit 4
