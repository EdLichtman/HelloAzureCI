write-output "beginning of nugetrestore"
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln

foreach ($SolutionFile in $AllSolutionFiles) {
    & nuget restore $SolutionFile
}
write-output "end of nugetrestore"