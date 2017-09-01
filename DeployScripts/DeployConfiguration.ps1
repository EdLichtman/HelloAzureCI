$ErrorActionPreference = "stop"
if ($env:SCM_TRACE_LEVEL -ne 4 ) {
  # Equivalent of Echo off -- set write-verbose to false?
  # @if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

#   $SaveVerbosePreference = $global:VerbosePreference;
# $global:VerbosePreference = 'SilentlyContinue';

# Import-module "Whatever";

# $global:VerbosePreference = $SaveVerbosePreference;
# Then I just call the script like so:

# PowerShell -file something.ps1 -Verbose

#https://stackoverflow.com/questions/22537863/suppressing-verbose-for-import-module
#$VerbosePreference
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

[Environment]::SetEnvironmentVariable("KUDU_SYNC_CMD",$null)
& npm uninstall kudusync -g --silent

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
[Environment]::SetEnvironmentVariable("MSBUILD_PATH",$null)
if (-not $env:MSBUILD_PATH) {
    $env:MSBUILD_PATH = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
}




#### Import UserDefined Variables from AppSettings
## To Define your custom variables, 
## add them to the Application Settings on Azure.
## Key should start with DEPLOYVAR_

#Transfer the Setting of UserDefinedVariables in Deploy Script configuration file, not PreDeploy steps.
$DeploymentSource = $Env:DEPLOYMENT_SOURCE
$DeploymentScriptsDirectory = "$DeploymentSource\DeployScripts"
$UserDefinedTestFolderIdentifier = $Env:APPSETTING_DEPLOYVAR_TestFolderIdentifier
$UserDefinedSolutionConfigurationIdentifier = $Env:APPSETTING_DEPLOYVAR_SolutionConfig
if (-not $UserDefinedTestFolderIdentifier) {
    $UserDefinedTestFolderIdentifier = "*Tests"
}
if (-not $UserDefinedSolutionConfigurationIdentifier) {
    $UserDefinedSolutionConfigurationIdentifier = "Solution_Configuration"
}
