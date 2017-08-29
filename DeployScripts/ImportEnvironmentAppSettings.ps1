#Declare Variables for use. Clear the App_Data folder
write-output "Declaring Local Variables and preparing appSettings and connectionStrings"
$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$MainProjectDir = $Env:MAIN_PROJECT_DIR
#Define folder in which you want to store various runtime config
$AppDataFolderName = (Get-ChildItem -Path $MainProjectDir).Where({$_.Name -like "Sample_*"}).Name.Replace("Sample_", "")


$EnvironmentVariables = Get-ChildItem Env: 

$appSettings = $EnvironmentVariables | where-object { $_.Name -like "APPSETTING*" }
$connectionStrings = $EnvironmentVariables | where-object {$_.Name -like "SQLAZURECONNSTR*"}

write-output "Clearing $AppDataFolderName Folder"
Remove-Item -path "$MainProjectDir\$AppDataFolderName" -recurse | Out-Null
New-Item -ItemType Directory -Path "$MainProjectDir\$AppDataFolderName" | Out-Null

#Create AppSettings.config
[xml]$appSettingsConfig = New-Object System.Xml.XmlDocument 
$declaration = $appSettingsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$appSettingsNode = $appSettingsConfig.CreateNode("element", "appSettings", $null)
$appSettingsConfig.AppendChild($declaration) | Out-Null

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

$appSettingsConfig.AppendChild($appSettingsNode) | Out-Null

Write-Output "Saving appSettings to: $MainProjectDir\$AppDataFolderName\appSettings.config"
$appSettingsConfig.save("$MainProjectDir\$AppDataFolderName\appSettings.config") | Out-Null





#Create ConnectionStrings.config
[xml]$connectionStringsConfig = New-Object System.Xml.XmlDocument
$declaration = $connectionStringsConfig.CreateXmlDeclaration("1.0", "UTF-8",$null)
$connectionStringsNode = $connectionStringsConfig.CreateNode("element", "connectionStrings", $null)

$connectionStringsConfig.AppendChild($declaration) | Out-Null

foreach ($connectionString in $connectionStrings) {
    $name = $connectionString.Name -replace 'SQLAZURECONNSTR_', ''
    $connection = $connectionString.Value
    if ($connection) {
        $keyValuePair = $connectionStringsConfig.CreateNode("element", "add", $null)
        $keyValuePair.SetAttribute("name", $name)
        $keyValuePair.SetAttribute("connectionString", $connection)
        
        $connectionStringsNode.AppendChild($keyValuePair)
    }
}

$connectionStringsConfig.AppendChild($connectionStringsNode) | Out-Null

Write-Output "Saving connectionStrings to: $MainProjectDir\$AppDataFolderName\connectionStrings.config"
$connectionStringsConfig.save("$MainProjectDir\$AppDataFolderName\connectionStrings.config") | Out-Null

& more "$MainProjectDir\$AppDataFolderName\appSettings.config"
& more "$MainProjectDir\$AppDataFolderName\connectionStrings.config"