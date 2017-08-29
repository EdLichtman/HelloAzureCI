write-output "beginning of nugetrestore"
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
write-output $AllSolutionFiles
foreach ($SolutionFile in $AllSolutionFiles) {
    write-Output $SolutionFile
    & nuget restore $SolutionFile
    write-output "Finished restoring $SolutionFile"
}
write-output "end of nugetrestore"