



$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"
$nuget = "nuget"
$nUnitFramework = "net-4.5"
$nUnitVersion = "3.7.0"

& $nuget install NUnit.ConsoleRunner -Version $nUnitVersion -o $PackagesDir

$nunit = "$ProjectDir\packages\NUnit.ConsoleRunner.$nUnitVersion\tools\nunit3-console.exe"
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
    exit 4
}