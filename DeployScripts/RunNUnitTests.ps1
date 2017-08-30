$ProjectDir = $Env:DEPLOYMENT_SOURCE

. "$ProjectDir\DeployScripts\NugetFunctions.ps1"

$UnitTestsDir = "$Env:CurrentUnitTestBeingTested"
$OutDir = "$UnitTestsDir\bin\Release"
$nUnitFramework = "net-4.5"
$PackagesDir = "$UnitTestsDir\packages"
$nUnitVersion = "3.7.0"

NugetInstall-Package "NUnit.ConsoleRunner" $nUnitVersion $PackagesDir

$nunit = "$ProjectDir\packages\NUnit.ConsoleRunner.$nUnitVersion\tools\nunit3-console.exe"
$tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)

Write-Output "nUnit Run location is... $nUnit"
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
    exit 4
}
exit 0