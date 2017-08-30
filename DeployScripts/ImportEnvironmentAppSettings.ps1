$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$CurrentProjectLocation = $Env:CURRENT_PROJECT_LOCATION
$CurrentProjectDirectory = "$MainSolutionDir\$CurrentProjectLocation"

Write-Output "`n----- Extracting the Application Settings from Azure to project ""$CurrentProjectLocation"" -----"
$AppDataFolderName = (Get-ChildItem -Path $CurrentProjectDirectory).Where({$_.Name -like "Sample_*"}).Name.Replace("Sample_", "")

$EnvironmentVariables = Get-ChildItem Env: 
$appSettings = $EnvironmentVariables | where-object { $_.Name -like "APPSETTING*" }
$connectionStrings = $EnvironmentVariables | where-object {$_.Name -like "SQLAZURECONNSTR*"}

write-output "Cleaning $CurrentProjectLocation\$AppDataFolderName`n"
Remove-Item -path "$CurrentProjectDirectory\$AppDataFolderName" -recurse | Out-Null
New-Item -ItemType Directory -Path "$CurrentProjectDirectory\$AppDataFolderName" | Out-Null


Write-Output "Creating $CurrentProjectLocation\$AppDataFolderName\appSettings.config"
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
Write-Output "Saving appSettings to: $CurrentProjectLocation\$AppDataFolderName\appSettings.config`n"
$appSettingsConfig.save("$CurrentProjectDirectory\$AppDataFolderName\appSettings.config") 
# other form of out-null >$null

Write-Output "Creating $CurrentProjectLocation\$AppDataFolderName\connectionStrings.config"
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

Write-Output "Saving connectionStrings to: $CurrentProjectLocation\$AppDataFolderName\connectionStrings.config`n"
$connectionStringsConfig.save("$CurrentProjectDirectory\$AppDataFolderName\connectionStrings.config")