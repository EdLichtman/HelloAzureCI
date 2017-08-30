$MainSolutionDir = $Env:DEPLOYMENT_SOURCE

Write-Output "`n----- Cleaning Solution -----"
$binDirectories =  (Get-ChildItem -Path $MainSolutionDir -recurse).Where({$_.PSIsContainer -and $_.FullName -like "*\bin"})
if ($binDirectories.Count -gt 0) {
    Write-Output "Removing the following Directories:"
    foreach ($binDirectory in $binDirectories) {
        Write-Output $binDirectory.FullName
        Remove-Item -path "$($binDirectory.FullName)" -recurse | Out-Null
    }
}
