# <?xml version="1.0" encoding="utf-8"?>  
# <RunSettings>  
#   <RunConfiguration>  
#     <TestAdaptersPaths>HelloAzureCIUnitTests\packages\NUnit3TestAdapter.3.8.0\build\net35</TestAdaptersPaths>  
#   </RunConfiguration>  
# </RunSettings>  

$ProjectDir = $Env:DEPLOYMENT_SOURCE
$UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"
$PackagesDir = "$UnitTestsDir\packages"
$nUnitTestAdaptersDir = "$PackagesDir\NUnit3TestAdapter.3.8.0\build\net35"

#Create xml document
[xml]$doc = New-Object System.Xml.XmlDocument
$declaration = $doc.CreateXmlDeclaration("1.0", "UTF-8",$null)
$runSettings = $doc.CreateNode("element", "RunSettings", $null)
$runConfiguration = $doc.CreateNode("element", "RunConfiguration", $null)
$testAdaptersPaths = $doc.CreateNode("element", "TestAdaptersPaths", $null)
$testAdaptersPaths.InnerText = $nUnitTestAdaptersDir

$runConfiguration.AppendChild($testAdaptersPaths)
$runSettings.AppendChild($runConfiguration)
$doc.AppendChild($declaration)
$doc.AppendChild($runSettings)

$doc.save("$ProjectDir\.runsettings")