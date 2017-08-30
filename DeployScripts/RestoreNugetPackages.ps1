
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
. "$MainSolutionDir\DeployScripts\Functions.ps1"

Write-Output "----- Restoring NuGet Packages -----"
$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $ErrorLevel = Restore-NugetPackagesOnSolution $SolutionFile.FullName
    
    if ($ErrorLevel -ne 0) { 
        write-output "exiting with error "$ErrorLevel
        throw $ErrorLevel
    }
    Write-Output "Restored NuGet Packages for $($SolutionFile.Name)"

}
