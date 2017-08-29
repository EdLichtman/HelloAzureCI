$MSBuild_Path = $Env:MSBUILD_PATH
$InPlaceDeployment = $Env:IN_PLACE_DEPLOYMENT

$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$MainProjectDir = $Env:MAIN_PROJECT_DIR

$MainProjectCsProjFile = (Get-ChildItem -Path "$MainProjectDir").Where({$_.Name -Like "*.csproj"}).FullName

if ($InPlaceDeployment -ne "1") {
        $arguments = @("$MainProjectCsProjFile"
                        ,"/nologo"
                        ,"/verbosity:m" 
                        ,"/t:Build" 
                        ,"/t:pipelinePreDeployCopyAllFilesToOneFolder" 
                        ,"/p:_PackageTempDir=""$Env:DEPLOYMENT_TEMP"";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false" 
                        ,"/p:SolutionDir=""$MainSolutionDir\.\\"""
                        ,"$Env:SCM_BUILD_ARGS")

    } else {
        $arguments = @(
            "$MainProjectCsProjFile"
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
    exit $lastexitcode
}
