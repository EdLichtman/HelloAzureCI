#Declare Variables for use. Clear the App_Data folder
write-output "Declaring Local Variables and preparing appSettings and connectionStrings"
$ProjectDir = $Env:DEPLOYMENT_SOURCE
$MainApplicationDir = "$ProjectDir\HelloAzureCI"

$EnvironmentVariables = Get-ChildItem Env: 

$appSettings = $EnvironmentVariables | where-object { $_.Name -like "APPSETTING*" }
$connectionStrings = $EnvironmentVariables | where-object {$_.Name -like "SQLAZURECONNSTR*"}

write-output "Clearing App_Data Folder"
Remove-Item -path "$MainApplicationDir\App_Data" -recurse
New-Item -ItemType Directory -Path "$MainApplicationDir\App_Data"


#Create AppSettings.config
[xml]$appSettingsConfig = New-Object System.Xml.XmlDocument
$declaration = $appSettingsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$appSettingsNode = $appSettingsConfig.CreateNode("element", "appSettings", $null)

$appSettingsConfig.AppendChild($declaration)

foreach ($appSetting in $appSettings) {
    $key = $appSetting.Name -replace 'APPSETTING_', ''
    $value = $appSetting.Value
    if ($key) {
        $keyValuePair = $appSettingsConfig.CreateNode("element", "add", $null)
        $keyValuePair.SetAttribute("key", $key)
        $keyValuePair.SetAttribute("value", $value)
        
        $appSettingsNode.AppendChild($keyValuePair)
    }
}

$appSettingsConfig.AppendChild($appSettingsNode)

Write-Output "Saving appSettings to: $MainApplicationDir\App_Data\appSettings.config"
$appSettingsConfig.save("$MainApplicationDir\App_Data\appSettings.config")





#Create ConnectionStrings.config
[xml]$connectionStringsConfig = New-Object System.Xml.XmlDocument
$declaration = $connectionStringsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$connectionStringsNode = $connectionStringsConfig.CreateNode("element", "connectionStrings", $null)

$connectionStringsConfig.AppendChild($declaration)

foreach ($connectionString in $connectionStrings) {
    $name = $connectionString.Name -replace 'SQLAZURECONNSTR_', ''
    $connection = $connectionString.ConnectionString
    $type = $connectionString.Type
    if ($connection) {
        $keyValuePair = $connectionStringsConfig.CreateNode("element", "add", $null)
        $keyValuePair.SetAttribute("name", $name)
        $keyValuePair.SetAttribute("connection", $connection)
        
        $connectionStringsNode.AppendChild($keyValuePair)
    }
}

$connectionStringsConfig.AppendChild($connectionStringsNode)

Write-Output "Saving connectionStrings to: $MainApplicationDir\App_Data\connectionStrings.config"
$connectionStringsConfig.save("$MainApplicationDir\App_Data\connectionStrings.config")