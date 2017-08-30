$MSBuild_Path = $Env:MSBUILD_PATH
$InPlaceDeployment = $Env:IN_PLACE_DEPLOYMENT

$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$UnitTestPaths = Get-ChildItem -Path $MainSolutionDir | Where-Object {$_.Name -Like "*Tests"}


foreach ($CurrentUnitTestFolder in $UnitTestPaths) {
    $UnitTestFolderPath = $CurrentUnitTestFolder.FullName
    $UnitTestProject = Get-ChildItem -Path "$UnitTestFolderPath" | Where-Object {$_.Name -Like "*.csproj"}
    $UnitTestProjectFile = $UnitTestProject.FullName

    $Env:CurrentUnitTestBeingTested = $UnitTestFolderPath
    if ($InPlaceDeployment -ne "1") {
            $arguments = @("$UnitTestProjectFile"
                            ,"/nologo"
                            ,"/verbosity:m" 
                            ,"/t:Build" 
                            ,"/t:pipelinePreDeployCopyAllFilesToOneFolder" 
                            ,"/p:_PackageTempDir=""$Env:DEPLOYMENT_TEMP"";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false" 
                            ,"/p:SolutionDir=""$UnitTestProject\.\\"""
                            ,"$Env:SCM_BUILD_ARGS")

        } else {
            $arguments = @(
                "$UnitTestProjectFile"
                ,"/nologo"
                ,"/verbosity:m"
                ,"/t:Build"
                ,"/p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false"
                ,"/p:SolutionDir=""$UnitTestProject\.\\"""
                ,"$Env:SCM_BUILD_ARGS"

            )
        }
    Write-Output "Running: & "$MSBuild_Path" $arguments" 
    & "$MSBuild_Path" $arguments
    & "$Env:DeployScriptsDir\RunNUnitTests.ps1"
    
    if ($lastexitcode -ne 0) {
        exit $lastexitcode
    }
}




