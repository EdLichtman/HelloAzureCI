$ErrorActionPreference = "stop"
if ($env:SCM_TRACE_LEVEL -eq 4 ) {
    #In the batch script if $env:SCM_TRACE_LEVEL is not 4
    #Set Echo to off. There isn't really an equivalent so 
    #since VerbosePreference is default Silent, if it is 4
    #We set it to "be verbose"
    $VerbosePreference = "Continue"
}

# -------------------------------
# KUDU Deployment Script 
# Version: 1.0.15
# (Converted to Powershell)
# -------------------------------

# -------------------------------
# Prerequisites
# -------------------------------

# Verify node.js installed
try {
& node --version
} catch {
  throw "Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment."
}


# -------------------------------
# SetUp
# -------------------------------

$env:ARTIFACTS = "$PSScriptRoot\..\artifacts" 

If (-not $env:DEPLOYMENT_TARGET) {
    $env:DEPLOYMENT_TARGET = "$ENV:ARTIFACTS\wwwroot"
}

If (-not $env:NEXT_MANIFEST_PATH) {
    $env:NEXT_MANIFEST_PATH = "$ENV:ARTIFACTS\manifest"
    
    If (-not $env:PREVIOUS_MANIFEST_PATH) {
        $env:PREVIOUS_MANIFEST_PATH = "$ENV:ARTIFACTS\manifest"
    }
}

If (-not $env:KUDU_SYNC_CMD) {
    #Install Kudu sync
    Write-Output "Installing Kudu Sync"
    & npm install kudusync -g --silent

    $env:KUDU_SYNC_CMD = "$env:APPDATA\npm\kuduSync.cmd"
}

If (-not $env:DEPLOYMENT_TEMP) {
    $env:DEPLOYMENT_TEMP = "$ENV:TEMP\___deployTemp$($(Get-Random -Minimum 0 -Maximum 32767))"
    $env:CLEAN_LOCAL_DEPLOYMENT_TEMP = "true"
}

If ($env:CLEAN_LOCAL_DEPLOYMENT_TEMP) {
    If (Test-Path $env:DEPLOYMENT_TEMP) {
         Remove-Item -recurse -force "$env:DEPLOYMENT_TEMP"
         New-Item -ItemType directory -Path "$env:DEPLOYMENT_TEMP"
    }
}

if (-not $env:MSBUILD_PATH) {
    $env:MSBUILD_PATH = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
}

$DeploymentSource = $Env:DEPLOYMENT_SOURCE
$DeploymentScriptsDirectory = "$DeploymentSource\DeployScripts"

#### Import UserDefined Variables from AppSettings
## To Define your custom variables, 
## add them to the Application Settings on Azure.
## Key should start with DEPLOYVAR_
$NonDeployableProjectIdentifierList = $Env:APPSETTING_DEPLOYVAR_NonDeployableProjectsIdentifiers
if (-not $NonDeployableProjectIdentifierList) {
    $NonDeployableProjectIdentifierList = "*Tests"
}
$NonDeployableProjectIdentifiers = $NonDeployableProjectIdentifierList -split ","

$UserDefinedTestFolderCommaDelimitedList = $Env:APPSETTING_DEPLOYVAR_TestFolderIdentifiers
if (-not $UserDefinedTestFolderCommaDelimitedList) {
    $UserDefinedTestFolderCommaDelimitedList = "*Tests"
}
$UserDefinedTestFolderIdentifiers = $UserDefinedTestFolderCommaDelimitedList -split ","

$UserDefinedSolutionConfigurationIdentifier = $Env:APPSETTING_DEPLOYVAR_SolutionConfig
if (-not $UserDefinedSolutionConfigurationIdentifier) {
    $UserDefinedSolutionConfigurationIdentifier = "Solution_Configuration"
}

$ShouldRunUnitTestsIdentifier = $Env:APPSETTING_DEPLOYVAR_ShouldRunTests
if (-not $ShouldRunUnitTestsIdentifier) {
    $ShouldRunUnitTestsIdentifier = "false"
}
if ($ShouldRunUnitTestsIdentifier -eq "false") {
    $ShouldRunUnitTests = $FALSE
}  else {
    $ShouldRunUnitTests = $TRUE
}

$SolutionConfigurationFolder = "$DeploymentSource\$UserDefinedSolutionConfigurationIdentifier"
$EnvironmentVariables = Get-ChildItem Env: 
$AllProjectDirectories = Get-ChildItem $DeploymentSource | Where-Object {$_.PSIsContainer -and (Test-Path -Path "$DeploymentSource\$_\*.csproj")} 
