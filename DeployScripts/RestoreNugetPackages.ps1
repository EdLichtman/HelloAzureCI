
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
. "$MainSolutionDir\DeployScripts\NugetFunctions.ps1"

Write-Output "----- Restoring NuGet Packages -----"
$AllSolutionFiles = Get-ChildItem -path "$MainSolutionDir" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $ErrorLevel = NugetRestore-Solution $SolutionFile.FullName
    
    if ($ErrorLevel -ne 0) { 
        write-output "exiting with error "$ErrorLevel
        throw $ErrorLevel
    }
    Write-Output "Restored NuGet Packages for $($SolutionFile.Name)"

}
