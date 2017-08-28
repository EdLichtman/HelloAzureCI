$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"

$nuget = "nuget"
& $nuget install NUnit.ConsoleRunner -Version 3.7.0 -o $PackagesDir

$nunit = "$ProjectDir\packages\NUnit.ConsoleRunner.3.7.0\tools\nunit3-console.exe"
$tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)
try {
    & $nunit $tests --noheader --framework=net-4.5 --work=$OutDir
} Catch {
    exit 4
}