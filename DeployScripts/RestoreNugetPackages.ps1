write-output "beginning of nugetrestore"
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
write-output $AllSolutionFiles
foreach ($SolutionFile in $AllSolutionFiles) {
    write-Output $SolutionFile
    write-output Hello World
    write-output "About to restore "$SolutionFile.FullName
    & nuget restore $SolutionFile.FullName
    write-output "Finished restoring $SolutionFile"
}
write-output "end of nugetrestore"