write-host Get-ChildItem Env
# $ProjectDir = $Env:DEPLOYMENT_SOURCE
# $UnitTestsDir = "$ProjectDir\HelloAzureCIUnitTests"

# $app = Get-AzureRmWebApp -Name 
# $appSettings = $app.siteconfig.AppSettings
# $connectionStrings = $app.siteconfig.ConnectionStrings

# $nameValues = ''

# foreach ($appSetting in $appSettings) {
#     $key = $appSetting.Name
#     $value = $appSetting.Value

#     $nameValues += @"
#     <add key="$key" value="$value" />

# "@

# }

# $appSettings =@"
# <?xml version="1.0" encoding="utf-8" ?>
# <appSettings>
# $nameValues
# </appSettings>
# "@

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

# $appSettings | out-file -filepath "$UnitTestsDir\App_Data\AppSettings.config"
# $connectionStrings | out-file -filepath "$UnitTestsDir\App_Data\connectionStrings.config"