$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
. "$MainSolutionDir\DeployScripts\Functions.ps1"

RunScript CleanAllSolutions
RunScript RestoreNugetPackages
#Todo: Write a script to find all csProj Files that aren't unit tests and combine these 2 into 1 command
RunScript ImportEnvironmentAppSettings
RunScript BuildSpecifiedProject
RunScript BuildAndRunAllUnitTests