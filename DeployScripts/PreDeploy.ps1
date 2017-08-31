#### Import UserDefined Variables from AppSettings
## To Define your custom variables, 
## add them to the Application Settings on Azure.
## Key should start with DEPLOYVAR_

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

#### Importing Environment Variables and External Function Files
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
. "$MainSolutionDir\DeployScripts\Functions.ps1"

#### Importing Application Settings and Configuration Settings from Azure Environment
Write-Output "`n----- Importing Application Settings and Configuration Settings from Azure Environment -----"
RunScript ImportEnvironmentAppSettings

#### Removing all Previously compiled code from entire solution
Write-Output "`n----- Removing all Previously compiled code from entire solution -----"
$binDirectories =  (Get-ChildItem -Path $MainSolutionDir -recurse).Where({$_.PSIsContainer -and $_.FullName -like "*\bin"})
if ($binDirectories.Count -gt 0) {
    Write-Output "Removing the following Directories:"
    foreach ($binDirectory in $binDirectories) {
        Write-Output $binDirectory.FullName
        Remove-Item -path "$($binDirectory.FullName)" -recurse | Out-Null
    }
}

#### Restoring NuGet Packages
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

#### Finding all directories that are defined as Project Directories, and contain a .csproj file
$AllProjectDirectories = Get-ChildItem $MainSolutionDir | Where-Object {$_.PSIsContainer -and (Test-Path -Path "$MainSolutionDir\$_\*.csproj")} 

#### Compiling all Non-Unit Test Projects from those directories based on UserDefined Naming Convention
Write-Output "----- Building all non-Test Projects -----"
$NonUnitTestProjectDirectories = $AllProjectDirectories | Where-Object {$_.Name -NotLike "$UserDefinedTestFolderIdentifier"}
foreach ($CurrentProjectDirectory in $NonUnitTestProjectDirectories) {
    $CurrentProjectPath = $CurrentProjectDirectory.Name
    
    Import-EnvironmentSettingsIntoProject $CurrentProjectPath $UserDefinedSolutionConfigurationIdentifier
    Build-DeployableProject $CurrentProjectPath 
}

#### Compiling all Unit Test Projects from those directories based on UserDefined Naming Convention
### Also Running NUnit Tests on those project dlls
Write-Output "`n----- Beginning Unit Tests -----"
$UnitTestProjectDirectories = $AllProjectDirectories | Where-Object {$_.Name -Like "$UserDefinedTestFolderIdentifier"}

foreach ($CurrentUnitTestDirectory in $UnitTestProjectDirectories) {
    $UnitTestFolderName = $CurrentUnitTestDirectory.Name
    Build-ProjectWithoutMSBuildArguments $UnitTestFolderName
    Run-nUnitTests $UnitTestFolderName
}