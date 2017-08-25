$ProjectDir = $Env:DEPLOYMENT_SOURCE
$MainApplicationDir = "$ProjectDir\HelloAzureCI"

$appSettings = $Env | where-object {$_.Name -contains "APPSETTING"} 
$connectionStrings = $Env | where-object {$_.Name -contains "CONNECTIONSTRING"} 

#AppSettings
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


#ConnectionStrings
[xml]$connectionStringsConfig = New-Object System.Xml.XmlDocument
$declaration = $connectionStringsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$connectionStringsNode = $appSettingsConfig.CreateNode("element", "connectionStrings", $null)

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





# $connectionStringValues = ''
# foreach ($connectionString in $connectionStrings) {
#     $name = $connectionString.Name
#     $connection = $connectionString.ConnectionString
#     $type = $connectionString.Type

#     $connectionStringValues += @"
#     <add name="$name" connectionString="$connection" />

# "@
# }

# $connectionStrings =@"
# <?xml version="1.0" encoding="utf-8" ?>
# <connectionStrings>
# $connectionStringValues
# </connectionStrings>
# "@


#$connectionStrings | out-file -filepath "$MainApplicationDir\App_Data\connectionStrings.config"
