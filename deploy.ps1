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
