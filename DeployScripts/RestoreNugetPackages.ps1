$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $SolutionFileExecutablePath = $SolutionFile.FullName
    write-output "& nuget restore $SolutionFileExecutablePath"
    try {& nuget restore $SolutionFileExecutablePath}catch{write-output $_.Exception.Message}
}
