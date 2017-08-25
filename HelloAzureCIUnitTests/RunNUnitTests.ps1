$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"

$nuget = "nuget"
& $nuget install NUnit3TestAdapter -Version 3.8.0 -o $PackagesDir

