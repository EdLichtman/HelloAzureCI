REM echo Beginning Kudu Deployment. Setting Environment Variables
REM @if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off


:: Setup
:: -----

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Beginning Custom Pre-Deploy Script

Call:RunPowershellScript Deploy
IF !ERRORLEVEL! NEQ 0 goto:error 

echo Synchronizing Test Repository with application root



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:RunPowershellScript
SET PowerShellScript="%DEPLOYMENT_SOURCE%\%~1.ps1"
Powershell.exe -executionpolicy remotesigned -Command "try { & """%PowerShellScript%""" } catch {exit 1}"
exit /b %ERRORLEVEL%

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo "An error has occurred during web site deployment."
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
