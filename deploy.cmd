@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.15
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

REM IF NOT DEFINED KUDU_SYNC_CMD (
REM   :: Install kudu sync
REM   echo Installing Kudu Sync
REM   call npm install kudusync -g --silent
REM   IF !ERRORLEVEL! NEQ 0 goto error

REM   :: Locally just running "kuduSync" would also work
REM   SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
REM )
IF NOT DEFINED DEPLOYMENT_TEMP (
  SET DEPLOYMENT_TEMP=%temp%\___deployTemp%random%
  SET CLEAN_LOCAL_DEPLOYMENT_TEMP=true
)

IF DEFINED CLEAN_LOCAL_DEPLOYMENT_TEMP (
  IF EXIST "%DEPLOYMENT_TEMP%" rd /s /q "%DEPLOYMENT_TEMP%"
  mkdir "%DEPLOYMENT_TEMP%"
)

IF DEFINED MSBUILD_PATH goto MsbuildPathDefined
SET MSBUILD_PATH=%ProgramFiles(x86)%\MSBuild\14.0\Bin\MSBuild.exe
:MsbuildPathDefined

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling .NET Web Application deployment.

:: 0. Restore Environment AppSettings

Powershell.exe -executionpolicy remotesigned -File "%DEPLOYMENT_SOURCE%\HelloAzureCIUnitTests\ImportEnvironmentAppSettings.ps1"

:: 1. Restore NuGet packages
IF /I "HelloAzureCI.sln" NEQ "" (
  call :ExecuteCmd nuget restore "%DEPLOYMENT_SOURCE%\HelloAzureCI.sln"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 2. Build to the temporary path
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\HelloAzureCI\HelloAzureCI.csproj" /nologo /verbosity:m /t:Build /t:pipelinePreDeployCopyAllFilesToOneFolder /p:_PackageTempDir="%DEPLOYMENT_TEMP%";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false /p:SolutionDir="%DEPLOYMENT_SOURCE%\.\\" %SCM_BUILD_ARGS%
) ELSE (
  call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\HelloAzureCI\HelloAzureCI.csproj" /nologo /verbosity:m /t:Build /p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false /p:SolutionDir="%DEPLOYMENT_SOURCE%\.\\" %SCM_BUILD_ARGS%
)

IF !ERRORLEVEL! NEQ 0 goto error

:: 2a. Build test project to temporary path
call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\HelloAzureCIUnitTests\HelloAzureCIUnitTests.csproj
IF !ERRORLEVEL! NEQ 0 goto error


:: 3. Run unit tests
:: 3a. Install NUnit3 Adapter
Powershell.exe -executionpolicy remotesigned -File "%DEPLOYMENT_SOURCE%\HelloAzureCIUnitTests\InstallNUnit3TestAdapter.ps1"
:: 3c. Call vstest.console
call :ExecuteCmd vstest.console.exe "%DEPLOYMENT_SOURCE%\HelloAzureCIUnitTests\bin\Debug\HelloAzureCIUnitTests.dll" /TestAdapterPath:"%DEPLOYMENT_SOURCE%\HelloAzureCIUnitTests\packages\NUnit3TestAdapter.3.8.0\build\net35\"

IF !ERRORLEVEL! NEQ 0 goto error

REM :: 3. KuduSync
REM IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
REM   call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_TEMP%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
REM   IF !ERRORLEVEL! NEQ 0 goto error
REM )

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:errorRunningTests
endlocal
echo An error has occurred while running unit tests.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.