$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"
$nuget = "nuget"
$framework = "net-4.5"

& $nuget install NUnit.ConsoleRunner -Version 3.7.0 -o $PackagesDir

$nunit = "$ProjectDir\packages\NUnit.ConsoleRunner.3.7.0\tools\nunit3-console.exe"
$tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)
try {
    & $nunit $tests --noheader --framework=$framework --work=$OutDir
    write-output HelloWorld
} Catch {
    write-output HelloWorldIMadeItToTheCatch
    exit 4
}
write-output HelloWorldIPassedTheTry
