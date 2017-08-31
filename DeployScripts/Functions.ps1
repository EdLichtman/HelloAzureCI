#### Importing Environment Variables and External Function Files
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

##############################
#.SYNOPSIS
#Runs Powershell Script
#
#.DESCRIPTION
#Runs Powershell Script via script name. Throws Error if Script Fails
#
#.PARAMETER ScriptName
#ScriptName should be the name of a ps1 file within the \DeployScripts folder. 
#It should not contain .ps1
#
#.EXAMPLE
#RunScript Functions
#

##############################
function RunScript {
    param([string] $ScriptName)
    $DeployScriptsDirectory = "$MainSolutionDir\DeployScripts"
    
    try {
        & "$DeployScriptsDirectory\$ScriptName.ps1"
        $errorLevel = 0
    } catch {
        write-output $_
        $errorLevel = 1
    }
    if ($errorLevel -ne 0) {
        Write-Output "Error while Running $ScriptName"
        throw $errorLevel
    }
    
    return
}

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
function Restore-NugetPackagesOnSolution {
    param ([string] $SolutionExecutablePath)
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
function Import-EnvironmentSettingsIntoProject {
    Param([string] $CurrentProjectLocation
        , [string] $UserDefinedSolutionConfigurationIdentifier)
    $CurrentProjectDirectory = "$MainSolutionDir\$CurrentProjectLocation"
    Write-Output "`n----- Copying Extracted AppSettings to ""$CurrentProjectLocation"" -----"
    $AppDataFolderName = (Get-ChildItem -Path $CurrentProjectDirectory).Where({$_.Name -like "Sample_*"}).Name.Replace("Sample_", "")
    $AppDataFolderLocation = "$CurrentProjectDirectory\$AppDataFolderName"

    write-output "Cleaning $AppDataFolderLocation`n"
    if (Test-Path $AppDataFolderLocation) {
        Remove-Item -path "$AppDataFolderLocation" -recurse | Out-Null
    }
    New-Item -ItemType Directory -Path "$AppDataFolderLocation" | Out-Null
    Copy-Item "$MainSolutionDir\$UserDefinedSolutionConfigurationIdentifier\*" "$AppDataFolderLocation"
    
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
function Build-DeployableProject {
    Param ([string] $CurrentProjectLocation)
    $CurrentProjectDirectory = "$MainSolutionDir\$CurrentProjectLocation"
    $MSBuild_Path = $Env:MSBUILD_PATH
    $InPlaceDeployment = $Env:IN_PLACE_DEPLOYMENT   

    Write-Output "`n----- Building $CurrentProjectLocation-----"

    $Current_csproj_File = (Get-ChildItem -Path "$CurrentProjectDirectory").Where({$_.Name -Like "*.csproj"}).FullName
    if ($InPlaceDeployment -ne "1") {
            $arguments = @("$Current_csproj_File"
                            ,"/nologo"
                            ,"/verbosity:m" 
                            ,"/t:Build" 
                            ,"/t:pipelinePreDeployCopyAllFilesToOneFolder" 
                            ,"/p:_PackageTempDir=""$Env:DEPLOYMENT_TEMP"";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false" 
                            ,"/p:SolutionDir=""$MainSolutionDir\.\\"""
                            ,"$Env:SCM_BUILD_ARGS")

        } else {
            $arguments = @(
                "$Current_csproj_File"
                ,"/nologo"
                ,"/verbosity:m"
                ,"/t:Build"
                ,"/p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false"
                ,"/p:SolutionDir=""$MainProjectDir\.\\"""
                ,"$Env:SCM_BUILD_ARGS"

            )
        }
    & "$MSBuild_Path" $arguments
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
function Build-ProjectWithoutMSBuildArguments {
    Param ([string] $CurrentProjectLocation)
    $MSBuild_Path = $Env:MSBUILD_PATH

    Write-Output "`n----- Building $CurrentProjectLocation-----"

    $Current_csproj_File = (Get-ChildItem -Path "$MainSolutionDir\$CurrentProjectLocation").Where({$_.Name -Like "*.csproj"}).FullName

    & "$MSBuild_Path" $Current_csproj_File
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
function Run-nUnitTests {
    Param ([string] $CurrentProjectLocation)
    $UnitTestsDir = "$MainSolutionDir\$CurrentProjectLocation"
    $OutDir = "$UnitTestsDir\bin\Debug"
    $nUnitFramework = "net-4.5"
    $nUnitVersion = "3.7.0"

    Write-Output "`n----- Running Unit Tests on $UnitTestsDir -----"
    
    $nunit = "$MainSolutionDir\packages\NUnit.ConsoleRunner.$nUnitVersion\tools\nunit3-console.exe"
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
    if ($NUnitOverallResult -ne "Passed")
    {
        throw "nUnit Tests Failed for $UnitTestsDir"
    }

}

