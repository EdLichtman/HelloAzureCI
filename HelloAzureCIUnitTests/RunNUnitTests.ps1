$ProjectDir = "."
$PackagesDir = "$ProjectDir\packages"
$OutDir = "$ProjectDir\bin\Debug"

# Install NUnit Test Runner
$nuget = "$ProjectDir\.nuget\nuget.exe"
& $nuget install NUnit.Runners  -Version 2.6.2 -o $PackagesDir

# Set nunit path test runner
$nunit = "$ProjectDir\packages\NUnit.Runners.2.6.2\tools\nunit-console.exe"

#Find tests in OutDir
$tests = (Get-ChildItem $OutDir -Recurse -Include *Tests.dll)

# Run tests
& $nunit /noshadow /framework:"net-4.0" /xml:"$OutDir\Tests.nunit.xml" $tests