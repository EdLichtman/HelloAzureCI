######################################################
####### Deployment Source Definition
# All of the scripts require Deployment Source 
# since we need Deployment Source to find the Scripts
######################################################
if (-not $env:DEPLOYMENT_SOURCE) {
  $env:DEPLOYMENT_SOURCE = "$PSScriptRoot"
}

######################################################
####### Configure Deployment Variables
######################################################
. "$env:DEPLOYMENT_SOURCE\DeployScripts\DeployConfiguration.ps1"

######################################################
####### Include Deployment functions
######################################################
. "$DeploymentScriptsDirectory\Functions.ps1"

######################################################
####### Run Deployment Script
######################################################
. "$DeploymentScriptsDirectory\DeploymentScript.ps1"
#Step 1
#Include DeployConfiguration.ps1
#Include Functions.ps1
#Run Deployment Script

# Write-Output "Running custom pre-deploy script..."
# #RunScript PreDeploy
# #Just run Script -- without the Ampersand
# Call:RunPowershellScript PreDeploy
# IF !ERRORLEVEL! NEQ 0 goto:error 

# echo Synchronizing Test Repository with application root



# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# goto end

# :RunPowershellScript
# SET PowerShellScript="%DEPLOYMENT_SOURCE%\DeployScripts\%~1.ps1"
# Powershell.exe -executionpolicy remotesigned -Command "try { & """%PowerShellScript%""" } catch {exit 1}"
# exit /b %ERRORLEVEL%

# :: Execute command routine that will echo out when error
# :ExecuteCmd
# setlocal
# set _CMD_=%*
# call %_CMD_%
# if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
# exit /b %ERRORLEVEL%

# :error
# endlocal
# echo "An error has occurred during web site deployment."
# call :exitSetErrorLevel
# call :exitFromFunction 2>nul

# :exitSetErrorLevel
# exit /b 1

# :exitFromFunction
# ()

# :end
# endlocal
# echo Finished successfully.
