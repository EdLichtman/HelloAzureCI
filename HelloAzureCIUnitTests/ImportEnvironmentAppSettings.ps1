$ProjectDir = $Env:DEPLOYMENT_SOURCE
$MainApplicationDir = "$ProjectDir\HelloAzureCI"

$appSettings = $Env | where-object {$_.Name -contains "APPSETTING"} 
$connectionStrings = $Env | where-object {$_.Name -contains "CONNECTIONSTRING"} 

#Create xml document
[xml]$appSettingsConfig = New-Object System.Xml.XmlDocument
$declaration = $appSettingsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$appSettings = $appSettingsConfig.CreateNode("element", "appSettings", $null)

$appSettingsConfig.AppendChild($declaration)

$nameValues = ''

foreach ($appSetting in $appSettings) {
    $key = $appSetting.Name
    $value = $appSetting.Value

    $keyValuePair = $appSettingsConfig.CreateNode("element", "add", $null)
    $keyValuePair.key = $key
    $keyValuePair.value = $value
    
    $appSettings.AppendChild($keyValuePair)
}

$appSettingsConfig.AppendChild($appSettings)
$appSettingsConfig.save("$MainApplicationDir\App_Data\AppSettings.config")
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
