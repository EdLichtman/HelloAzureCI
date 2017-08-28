
#Declare Variables for use. Clear the App_Data folder
Write-Host Declaring Local Variables and preparing appSettings and connectionStrings
$ProjectDir = $Env:DEPLOYMENT_SOURCE
$MainApplicationDir = "$ProjectDir\HelloAzureCI"

$appSettings = $Env | where-object {$_.Name -contains "APPSETTING"} 
$connectionStrings = $Env | where-object {$_.Name -contains "CONNECTIONSTRING"} 

Write-Host Clearing App_Data Folder
Remove-Item -path "$MainApplicationDir\App_Data" -recurse
New-Item -ItemType Directory -Path "$MainApplicationDir\App_Data"


#Create AppSettings.config
[xml]$appSettingsConfig = New-Object System.Xml.XmlDocument
$declaration = $appSettingsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$appSettingsNode = $appSettingsConfig.CreateNode("element", "appSettings", $null)

$appSettingsConfig.AppendChild($declaration)

foreach ($appSetting in $appSettings) {
    $key = $appSetting.Name
    $value = $appSetting.Value
    if ($key) {
        $keyValuePair = $appSettingsConfig.CreateNode("element", "add", $null)
        $keyValuePair.key = $key
        $keyValuePair.value = $value
        
        $appSettingsNode.AppendChild($keyValuePair)
    }
}

$appSettingsConfig.AppendChild($appSettingsNode)
$appSettingsConfig.save("$MainApplicationDir\App_Data\appSettings.config")





#Create ConnectionStrings.config
[xml]$connectionStringsConfig = New-Object System.Xml.XmlDocument
$declaration = $connectionStringsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$connectionStringsNode = $connectionStringsConfig.CreateNode("element", "connectionStrings", $null)

$connectionStringsConfig.AppendChild($declaration)

foreach ($connectionString in $connectionStrings) {
    $name = $connectionString.Name
    $connection = $connectionString.ConnectionString
    $type = $connectionString.Type
    if ($connection) {
        $keyValuePair = $connectionStringsConfig.CreateNode("element", "add", $null)
        $keyValuePair.key = $key
        $keyValuePair.value = $value
        
        $connectionStringsNode.AppendChild($keyValuePair)
    }
}

$connectionStringsConfig.AppendChild($connectionStringsNode)
$connectionStringsConfig.save("$MainApplicationDir\App_Data\connectionStrings.config")

write-host debug values:
write-host "$MainApplicationDir\App_Data"
write-host $appSettingsConfig
write-host $connectionStringsConfig

