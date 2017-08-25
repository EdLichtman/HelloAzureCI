$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$OutDir = "$UnitTestsDir\bin\Debug"

$nuget = "nuget"
& $nuget install NUnit3TestAdapter -o $PackagesDir

