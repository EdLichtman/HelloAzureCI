$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$UserDefinedSolutionConfigurationIdentifier = $Env:APPSETTING_DEPLOYVAR_SolutionConfig
$DeployScriptsDirectory = "$MainSolutionDir\DeployScripts"

function RunScript {
    param([string] $ScriptName)
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

function Restore-NugetPackagesOnSolution {
    param ([string] $SolutionExecutablePath)
    Start-Job -Name RunNugetCommand -Scriptblock {param($sln)
        & nuget restore "$sln" 2>&1 | Out-Null
        write-output $lastExitCode
    } -Arg "$SolutionExecutablePath" | Out-Null
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job 

    return $ErrorLevel
}

function Import-EnvironmentSettingsIntoProject {
    Param([string] $CurrentProjectLocation)
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

function Build-UnitTestProject {
    Param ([string] $CurrentProjectLocation)
    $CurrentProjectDirectory = "$MainSolutionDir\$CurrentProjectLocation"
    $MSBuild_Path = $Env:MSBUILD_PATH

    Write-Output "`n----- Building $CurrentProjectLocation-----"

    $Current_csproj_File = (Get-ChildItem -Path "$CurrentProjectDirectory").Where({$_.Name -Like "*.csproj"}).FullName

    & "$MSBuild_Path" $Current_csproj_File
    if ($lastexitcode -ne 0) {
        throw "Could not build $CurrentProjectDirectory"
    }
    return
}

function Run-nUnitTests {
    Param ([string] $UnitTestsDir)
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

