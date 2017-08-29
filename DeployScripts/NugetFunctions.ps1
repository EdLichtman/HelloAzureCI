function NugetRestore-Solution {
    param ([string] $SolutionExecutablePath)
    Start-Job -Name RunNugetCommand -Scriptblock {param($sln)
        & nuget restore "$sln" 2>&1 | Out-Null
        write-output $lastExitCode
    } -Arg "$SolutionExecutablePath" | Out-Null
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job 

    return $ErrorLevel
}

function NugetInstall-Package {
    param ( [string] $PackageName
            ,[string] $nUnitVersionNumber
            ,[string] $PackagesDirectory

            )
    Start-Job -Name RunNugetCommand -Scriptblock {param($sln)
        & nuget install $PackageName -Version $nUnitVersionNumber -o $PackagesDirectory 2>&1 | Out-Null
        write-output $lastExitCode
    } -Arg "$SolutionExecutablePath" | Out-Null
    $ErrorLevel = Get-Job -Name RunNugetCommand | Wait-Job | Receive-Job 

    return $ErrorLevel
}