$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
. "$MainSolutionDir\DeployScripts\Functions.ps1"

$MSBuild_Path = $Env:MSBUILD_PATH

Write-Output "`n----- Beginning Unit Tests -----"
$UnitTestPaths = Get-ChildItem -Path $MainSolutionDir | Where-Object {$_.Name -Like "*Tests"}

foreach ($CurrentUnitTestFolder in $UnitTestPaths) {
    $UnitTestFolderPath = $CurrentUnitTestFolder.FullName
    $UnitTestProject = Get-ChildItem -Path "$UnitTestFolderPath" | Where-Object {$_.Name -Like "*.csproj"}
    $UnitTestProjectName = $UnitTestProject.Name
    $Env:CURRENT_PROJECT_NAME = $UnitTestProjectName
    $Env:CURRENT_PROJECT_LOCATION = Get-DeploymentPath $CurrentUnitTestFolder 
    
    & "$MSBuild_Path" $UnitTestProject.FullName
    RunScript RunNUnitTests
}




