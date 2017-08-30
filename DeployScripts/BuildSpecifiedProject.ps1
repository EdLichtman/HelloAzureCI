$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$CurrentProjectLocation = $Env:CURRENT_PROJECT_LOCATION
$CurrentProjectDirectory = "$MainSolutionDir\$CurrentProjectLocation"

$MSBuild_Path = $Env:MSBUILD_PATH
$InPlaceDeployment = $Env:IN_PLACE_DEPLOYMENT

Write-Output "`n----- Building $CurrentProjectLocation-----"

$Current_csproj_File = (Get-ChildItem -Path "$CurrentProjectDirectory").Where({$_.Name -Like "*.csproj"}).FullName
Write-Output $Current_csproj_File
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
