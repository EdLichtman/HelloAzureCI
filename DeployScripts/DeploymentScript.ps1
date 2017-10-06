#### Importing Application Settings and Configuration Settings from Azure Environment
Write-Output "`n----- Importing Application Settings and Configuration Settings from Azure Environment -----"

if (Test-Path $SolutionConfigurationFolder) {
    Remove-Item -path "$SolutionConfigurationFolder" -recurse | Out-Null
}
New-Item -ItemType Directory -Path "$SolutionConfigurationFolder" | Out-Null

$appSettings = $EnvironmentVariables | where-object { $_.Name -like "APPSETTING*" -and $_.Name -NotLike "*DEPLOYVAR*"}
$appSettingConfiguration = New-Object 'object[]' $appSettings.Count
for ($i=0; $i -le $appSettings.Count - 1; $i++) {
    $appSetting = $appSettings[$i]
    $appSettingConfiguration[$i] = @{
        "key"="$($appSetting.Name -replace 'APPSETTING_', '')";
        "value"="$($appSetting.Value)"
    }
}
Create-ConfigurationXML $SolutionConfigurationFolder $appSettingConfiguration "appSettings.config" "appSettings"

$connectionStrings = $EnvironmentVariables | where-object {$_.Name -like "SQLAZURECONNSTR*"}
$connectionStringConfiguration = New-Object 'object[]' $connectionStrings.Count
for ($i=0; $i -le $connectionStrings.Count - 1; $i++) {
    $connectionString = $connectionStrings[$i]
    
    $connectionStringConfiguration[$i] = @{
        "name"="$($connectionString.Name -replace 'SQLAZURECONNSTR_', '')";
        "connectionString"="$($connectionString.Value)"
        
    }

}
Create-ConfigurationXML $SolutionConfigurationFolder $connectionStringConfiguration "connectionStrings.config" "connectionStrings"


#### Removing all Previously compiled code from entire solution
Write-Output "`n----- Removing all Previously compiled code from entire solution -----"
$binDirectories =  (Get-ChildItem -Path $DeploymentSource -recurse).Where({$_.PSIsContainer -and $_.FullName -like "*\bin"})
if ($binDirectories.Count -gt 0) {
    Write-Output "Removing the following Directories:"
    foreach ($binDirectory in $binDirectories) {
        Write-Output $binDirectory.FullName
        Remove-Item -path "$($binDirectory.FullName)" -recurse | Out-Null
    }
}

#### Restoring NuGet Packages
Write-Output "----- Restoring NuGet Packages -----"
$AllSolutionFiles = Get-ChildItem -path "$DeploymentSource" -recurse -Include *.sln
foreach ($SolutionFile in $AllSolutionFiles) {
    $ErrorLevel = Restore-NugetPackagesOnSolution $SolutionFile.FullName
    
    if ($ErrorLevel -ne 0) { 
        write-output "exiting with error "$ErrorLevel
        throw $ErrorLevel
    }
    Write-Output "Restored NuGet Packages for $($SolutionFile.Name)"

}

#### Compiling all Non-Unit Test Projects from those directories based on UserDefined Naming Convention
Write-Output "----- Building all non-Test Projects -----"


$NonUnitTestProjectDirectories = @()
$UnitTestProjectDirectories = @()
foreach($projectDirectory in $AllProjectDirectories) {
    $projectIsDeployable = $TRUE

    if (ValidateIf-NotDeployable $projectDirectory.Name) {
        $projectIsDeployable = $FALSE
    }
    if (ValidateIf-IsTest $projectDirectory.Name) {
        $projectIsDeployable = $FALSE
    }

    if ($projectIsDeployable) {
        $NonUnitTestProjectDirectories += $projectDirectory
    } else {
        $UnitTestProjectDirectories += $projectDirectory
    }
}


foreach ($CurrentProjectDirectory in $NonUnitTestProjectDirectories) {
    $CurrentProjectPath = $CurrentProjectDirectory.Name
    
    Import-EnvironmentSettingsIntoProject $CurrentProjectPath $UserDefinedSolutionConfigurationIdentifier
    Build-DeployableProject $CurrentProjectPath 
}

#### Compiling all Unit Test Projects from those directories based on UserDefined Naming Convention
### Also Running NUnit Tests on those project dlls
 Write-Output "`n----- Beginning Work on Test Directories -----"
foreach ($CurrentUnitTestDirectory in $UnitTestProjectDirectories) {
    $UnitTestFolderName = $CurrentUnitTestDirectory.Name
    Build-ProjectWithoutMSBuildArguments $UnitTestFolderName

    if ($ShouldRunUnitTests) {
        if (ValidateIf-IsTest $UnitTestFolderName) {
            Run-nUnitTests $UnitTestFolderName
        }
    }

}

#### Run KuduSync to Synchronize Test Repo with Root
if ($env:IN_PLACE_DEPLOYMENT -ne 1) {
    & "$env:KUDU_SYNC_CMD" -v 50 -f "$env:DEPLOYMENT_TEMP" -t "$env:DEPLOYMENT_TARGET" -n "$env:NEXT_MANIFEST_PATH" -p "$env:PREVIOUS_MANIFEST_PATH" -i ".git;.hg;.deployment;deploy.cmd"
}

Write-Output "Deploy Successful!"