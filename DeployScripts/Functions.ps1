##############################
#.SYNOPSIS
#Restores NuGet Packages on entire solution
#
#.DESCRIPTION
#Recieves a .sln file and runs nuget restore against it to import all packages 
#that are missing from source control
#
#.PARAMETER SolutionExecutablePath
#SolutionExecutablePath is a .sln file. 
#
#.EXAMPLE
#Restore-NugetPackagesOnSolution HelloAzureCI.sln
#
#.NOTES
#There can be multiple .sln files in a git-versioned repository
##############################
function Restore-NugetPackagesOnSolution([string] $SolutionExecutablePath) {
    Start-Job -Name RunNugetCommand -Scriptblock {param($sln)
        & nuget restore "$sln" 2>&1 | Out-Null
        write-output $lastExitCode
    } -Arg "$SolutionExecutablePath" | Out-Null
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job 

    return $ErrorLevel
}

##############################
#.SYNOPSIS
#Imports Solution Configuration into specified Project
#
#.DESCRIPTION
#Takes the AppSettings, ConnectionStrings and other Solution Configuration and imports it into specified project
#
#.PARAMETER CurrentProjectLocation
#Path to Project top-most folder from root
#
#.PARAMETER UserDefinedSolutionConfigurationIdentifier
#Name of Folder holding Environment Solution Configuration
#
#.EXAMPLE
#Import-EnvironmentSettingsIntoProject HelloAzureCI Solution_Configuration
#Import-EnvironmentSettingsIntoProject $ProjectName $ENV:USER_DEFINED_SOLUTION_CONFIGURATION
#
#.NOTES
#General notes
##############################
function Import-EnvironmentSettingsIntoProject([string] $CurrentProjectLocation
                                            , [string] $UserDefinedSolutionConfigurationIdentifier) {

    $CurrentProjectDirectory = "$DeploymentSource\$CurrentProjectLocation"
    Write-Output "`n----- Copying Extracted AppSettings to ""$CurrentProjectLocation"" -----"
    $AppDataFolderName = (Get-ChildItem -Path $CurrentProjectDirectory).Where({$_.Name -like "Sample_*"}).Name.Replace("Sample_", "")
    $AppDataFolderLocation = "$CurrentProjectDirectory\$AppDataFolderName"

    
    if (Test-Path $AppDataFolderLocation) {
        write-output "Removing files from $AppDataFolderLocation`n"
        Remove-Item -path "$AppDataFolderLocation" -recurse | Out-Null
    }
    New-Item -ItemType Directory -Path "$AppDataFolderLocation" | Out-Null
    
    Write-Output "Copying Files from $UserDefinedSolutionConfigurationIdentifier to $AppDataFolderLocation"
    Copy-Item "$DeploymentSource\$UserDefinedSolutionConfigurationIdentifier\*" "$AppDataFolderLocation"
    
    return
}

##############################
#.SYNOPSIS
#Builds a project that can be deployed.
#
#.DESCRIPTION
#Builds a project that can be deployed, and used. Projects like Unit Tests Projects can't be used other than for Deploy Process.
#
#.PARAMETER CurrentProjectLocation
#Path to Project top-most folder from root
#
#.EXAMPLE
#Build-DeployableProject HelloAzureCI
#
#.NOTES
#This is different because it uses Kudu-Specific arguments alongside MSBuild
##############################
function Build-DeployableProject([string] $CurrentProjectLocation) {
     
    $CurrentProjectDirectory = "$DeploymentSource\$CurrentProjectLocation"

    Write-Output "`n----- Building $CurrentProjectLocation-----"

    $Current_csproj_File = (Get-ChildItem -Path "$CurrentProjectDirectory").Where({$_.Name -Like "*.csproj"}).FullName
    if ($env:IN_PLACE_DEPLOYMENT  -ne "1") {
            $arguments = @("$Current_csproj_File"
                            ,"/nologo"
                            ,"/verbosity:m" 
                            ,"/t:Build" 
                            ,"/t:pipelinePreDeployCopyAllFilesToOneFolder" 
                            ,"/p:_PackageTempDir=""$Env:DEPLOYMENT_TEMP"";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false" 
                            ,"/p:SolutionDir=""$DeploymentSource\.\\"""
                            ,"$Env:SCM_BUILD_ARGS")

        } else {
            $arguments = @(
                "$Current_csproj_File"
                ,"/nologo"
                ,"/verbosity:m"
                ,"/t:Build"
                ,"/p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false"
                ,"/p:SolutionDir=""$DeploymentSource\.\\"""
                ,"$Env:SCM_BUILD_ARGS"

            )
        }
    & "$env:MSBUILD_PATH" $arguments
    if ($lastexitcode -ne 0) {
        throw "Could not build $CurrentProjectDirectory"
    }
    return
}

##############################
#.SYNOPSIS
#Builds a project without MSBuild Arguments
#
#.DESCRIPTION
#Builds a project without MSBuild Arguments
#
#.PARAMETER CurrentProjectLocation
#Path to Project top-most folder from root
#
#.EXAMPLE
#Build-ProjectWithoutMSBuildArguments HelloAzureCIUnitTests
#
#.NOTES
#Used when the project is not deployable
##############################
function Build-ProjectWithoutMSBuildArguments([string] $CurrentProjectLocation) {
    Write-Output "`n----- Building $CurrentProjectLocation-----"

    $Current_csproj_File = (Get-ChildItem -Path "$DeploymentSource\$CurrentProjectLocation").Where({$_.Name -Like "*.csproj"}).FullName

    & "$env:MSBUILD_PATH" $Current_csproj_File /verbosity:m /p:SolutionDir="$DeploymentSource\.\\"
    if ($lastexitcode -ne 0) {
        throw "Could not build $CurrentProjectLocation"
    }
    return
}

##############################
#.SYNOPSIS
#Runs nUnit Tests against Project
#
#.DESCRIPTION
#Runs nUnit Tests against a test project. 
#Writes the Pass/Fail rate to the output and throws error 
#if test cases do not pass.
#
#.PARAMETER CurrentProjectLocation
#Path to Project top-most folder from root
#
#.EXAMPLE
#Run-nUnitTests HelloAzureCIUnitTests
#
##############################
function Run-nUnitTests([string] $CurrentProjectLocation) {
    $UnitTestsDir = "$DeploymentSource\$CurrentProjectLocation"
    $OutDir = "$UnitTestsDir\bin\Debug"
    $nUnitFramework = "net-4.5"
    $nUnitVersion = "3.7.0"

    Write-Output "`n----- Running Unit Tests on $UnitTestsDir -----"
    
    $nunit = "$DeploymentSource\packages\NUnit.ConsoleRunner.$nUnitVersion\tools\nunit3-console.exe"
    $tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)

    $NUnitTestResults = & $nunit $tests --noheader --framework=$nUnitFramework --work=$OutDir 
    $NUnitOverallResult = "Failed"
    $NUnitTestResults | ForEach-Object {
        $trimmedResult = $_.trim()
        if ($trimmedResult -like "Overall Result*") {
            $NUnitOverallResult = $trimmedResult -replace 'Overall Result: ', ''
        }     
    }
    Write-Output $NUnitTestResults
    if ($NUnitOverallResult -eq "Failed" -or $NUnitOverallResult -eq "Inconclusive")
    {
        throw "nUnit Tests Failed for $UnitTestsDir"
    }

}

##############################
#.SYNOPSIS
#Creates a configuration xml file
#
#.DESCRIPTION
#Creates a solution configuration xml file on the basis: 
#1. It is one level deep
#2. Each child Property is "add" and you declare attributes
#
#.PARAMETER SolutionConfigurationFolder
#Parameter description
#
#.PARAMETER EnvironmentVariablesConfiguration
#Parameter description
#
#.PARAMETER nameOfConfigurationFile
#Parameter description
#
#.PARAMETER nameOfConfigurationNode
#Parameter description
#
#.EXAMPLE
#An example
#
#.NOTES
#General notes
##############################
function Create-ConfigurationXML ($SolutionConfigurationFolder
                                ,$EnvironmentVariablesConfiguration
                                ,$nameOfConfigurationFile
                                ,$nameOfConfigurationNode) {

    $CompleteConfigurationFilePath = "$SolutionConfigurationFolder\$nameOfConfigurationFile"

    Write-Output "Creating $nameOfConfigurationFile"
    [xml]$configFile = New-Object System.Xml.XmlDocument 
    $declaration = $configFile.CreateXmlDeclaration("1.0","UTF-8",$null)
    $configFile.AppendChild($declaration) | Out-Null

    $mainConfigurationNode = $configFile.CreateNode("element", "$nameOfConfigurationNode", $null)
    $configFile.AppendChild($mainConfigurationNode)

    foreach ($configuration in $EnvironmentVariablesConfiguration) {
        $configurationNode = $configFile.CreateNode("element", "add", $null)
        foreach ($key in $configuration.keys) {
            $configurationNode.SetAttribute("$key", $configuration.Item($key))
        }
        $mainConfigurationNode.AppendChild($configurationNode) | Out-Null
    }
    

    Write-Output "Saving $nameOfConfigurationNode to: $CompleteConfigurationFilePath`n"
    $configFile.save("$CompleteConfigurationFilePath") 
}

function ValidateIf-NotDeployable($projectFolderName) {
    $IsDeployable = $TRUE
    foreach ($NonDeployableIdentifier in $NonDeployableProjectIdentifiers) {
        if($projectFolderName -Like $NonDeployableIdentifier) {
            $IsDeployable = $FALSE
        }
    }
    $IsDeployable -eq 0
}

function ValidateIf-IsTest($projectFolderName) {
    $IsTest = $FALSE
    foreach ($TestProjectIdentifier in $UserDefinedTestFolderIdentifiers) {
        if($projectFolderName -Like $TestProjectIdentifier) {
            $IsTest = $TRUE
        }
    }
    $IsTest -eq 1
}