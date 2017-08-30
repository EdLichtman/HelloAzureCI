$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$Env:CURRENT_PROJECT_LOCATION"
. "$ProjectDir\DeployScripts\NugetFunctions.ps1"


$OutDir = "$UnitTestsDir\bin\Release"
$nUnitFramework = "net-4.5"
$PackagesDir = "$UnitTestsDir\packages"
$nUnitVersion = "3.7.0"

Write-Output "`n----- Running Unit Tests on $UnitTestsDir -----"

NugetInstall-Package "NUnit.ConsoleRunner" $nUnitVersion $PackagesDir

$nunit = "$PackagesDir\NUnit.ConsoleRunner.$nUnitVersion\tools\nunit3-console.exe"
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
