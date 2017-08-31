$MainSolutionDir = $Env:DEPLOYMENT_SOURCE
$UserDefinedSolutionConfigurationIdentifier = $Env:APPSETTING_DEPLOYVAR_SolutionConfig
$SolutionConfigurationFolder = "$MainSolutionDir\$UserDefinedSolutionConfigurationIdentifier"

if (Test-Path $SolutionConfigurationFolder) {
    Remove-Item -path "$SolutionConfigurationFolder" -recurse | Out-Null
}
New-Item -ItemType Directory -Path "$SolutionConfigurationFolder" | Out-Null

$EnvironmentVariables = Get-ChildItem Env: 
$appSettings = $EnvironmentVariables | where-object { $_.Name -like "APPSETTING*" -and $_.Name -NotLike "*DEPLOYVAR*"}
$connectionStrings = $EnvironmentVariables | where-object {$_.Name -like "SQLAZURECONNSTR*"}

Write-Output "Creating $SolutionConfigurationFolder\appSettings.config"
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
Write-Output "Saving appSettings to: $SolutionConfigurationFolder\appSettings.config`n"
$appSettingsConfig.save("$SolutionConfigurationFolder\appSettings.config") 
# other form of out-null >$null

Write-Output "Creating $SolutionConfigurationFolder\connectionStrings.config"
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

Write-Output "Saving connectionStrings to: $SolutionConfigurationFolder\connectionStrings.config`n"
$connectionStringsConfig.save("$SolutionConfigurationFolder\connectionStrings.config")