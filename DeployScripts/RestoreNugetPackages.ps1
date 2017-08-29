$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln

foreach ($SolutionFile in $AllSolutionFiles) {
    & nuget restore $SolutionFile
}