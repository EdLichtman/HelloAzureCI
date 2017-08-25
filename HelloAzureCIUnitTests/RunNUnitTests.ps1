$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"

# Install NUnit Test Runner
$nuget = "nuget"
& $nuget install NUnit.Runners  -Version 2.6.2 -o $PackagesDir

# Set nunit path test runner
$nunit = "$UnitTestsDir\packages\NUnit.Runners.2.6.2\tools\nunit-console.exe"

#Find tests in OutDir
$tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)

# Run tests
& $nunit /noshadow /framework:"net-4.0" /xml:"$OutDir\Tests.nunit.xml" $tests