
$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$Env:CurrentUnitTestBeingTested"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"
$nuget = "nuget"
$nUnitFramework = "net-4.5"
$nUnitVersion = "3.7.0"
Write-Output "Line 9 of RunNUnitTests"
& $nuget install NUnit.ConsoleRunner -Version $nUnitVersion -o $PackagesDir

& more "$UnitTestsDir\App_Data\appSettings.config"
& more "$UnitTestsDir\App_Data\connectionStrings.config"

$nunit = "$ProjectDir\packages\NUnit.ConsoleRunner.$nUnitVersion\tools\nunit3-console.exe"
$tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)
Write-Output "Line 14 of RunNUnitTests"
$NUnitTestResults = & $nunit $tests --noheader --framework=$nUnitFramework --work=$OutDir
Write-Output "Line 16 of RunNUnitTests"
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