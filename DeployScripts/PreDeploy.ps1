$UserDefinedTestFolderIdentifier = $Env:APPSETTING_DEPLOYVAR_TestFolderIdentifier
$UserDefinedSolutionConfigurationIdentifier = $Env:APPSETTING_DEPLOYVAR_SolutionConfig
if (-not $UserDefinedTestFolderIdentifier) {
    $UserDefinedTestFolderIdentifier = "*Tests"
    $Env:APPSETTING_DEPLOYVAR_TestFolderIdentifier = $UserDefinedTestFolderIdentifier
}
if (-not $UserDefinedSolutionConfigurationIdentifier) {
    $UserDefinedSolutionConfigurationIdentifier = "Solution_Configuration"
    $Env:APPSETTING_DEPLOYVAR_SolutionConfig = $UserDefinedSolutionConfigurationIdentifier
}

$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$MSBuild_Path = $Env:MSBUILD_PATH
. "$MainSolutionDir\DeployScripts\Functions.ps1"


Write-Output "`n----- Extracting the Application Settings from Azure -----"
RunScript ImportEnvironmentAppSettings

Write-Output "`n----- Cleaning all Compiled Code from Solution -----"
$binDirectories =  (Get-ChildItem -Path $MainSolutionDir -recurse).Where({$_.PSIsContainer -and $_.FullName -like "*\bin"})
if ($binDirectories.Count -gt 0) {
    Write-Output "Removing the following Directories:"
    foreach ($binDirectory in $binDirectories) {
        Write-Output $binDirectory.FullName
        Remove-Item -path "$($binDirectory.FullName)" -recurse | Out-Null
    }
}

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

$AllProjectDirectories = Get-ChildItem $MainSolutionDir | Where-Object {$_.PSIsContainer -and (Test-Path -Path "$MainSolutionDir\$_\*.csproj")} 

Write-Output "----- Building all non-Test Projects -----"
$NonUnitTestProjectDirectories = $AllProjectDirectories | Where-Object {$_.Name -NotLike "$UserDefinedTestFolderIdentifier"}
foreach ($CurrentProjectDirectory in $NonUnitTestProjectDirectories) {
    $CurrentProjectPath = $CurrentProjectDirectory.Name
    
    Import-EnvironmentSettingsIntoProject $CurrentProjectPath
    Build-DeployableProject $CurrentProjectPath 
}

Write-Output "`n----- Beginning Unit Tests -----"
$UnitTestProjectDirectories = $AllProjectDirectories | Where-Object {$_.Name -Like "$UserDefinedTestFolderIdentifier"}

foreach ($CurrentUnitTestDirectory in $UnitTestProjectDirectories) {
    $UnitTestFolderPath = $CurrentUnitTestDirectory.FullName
    Build-UnitTestProject $UnitTestFolderPath
    Run-nUnitTests $UnitTestFolderPath
}