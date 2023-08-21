
#----------------------------------------------------------------------------------------------------
#--DIRSCAN [POWERSHELL SCRIPT]-----------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

<#
----------------------------------------------------------------------------------------------------
Author: John Barry
Date: 8/16/2023
Purpose: Scan a Directory to sort out which Directories contain the most files.
----------------------------------------------------------------------------------------------------
#>

#TO-DO JOHN: Compare the performance of EnumerateFileSystemEntries vs Get-ChildItem

Clear-Host                      # Clear terminal screen
Remove-Variable -Name * -ea 0   # Remove possible variable conflicts (-ErrorAction SilentlyContinue == -ea 0)
[System.GC]::Collect()          # Force a garbage collection

#----------------------------------------------------------------------------------------------------
#--INITIALIZATION------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

$USE_CURRENT_DIRECTORY =    $false      # Option to start in current directory [PWD]
$DIR_START =                "C:\Tests"  # Directory to scan
$MAX_JOBS =                 8           # Max number of threads to spawn

$DIR_QUEUE = New-Object System.Collections.Queue                # Directory Queue
$JOB_LIST = New-Object System.Collections.ArrayList($MAX_JOBS)  # Job List

$DIR_QUEUE = [System.Collections.Queue]::Synchronized( (New-Object System.Collections.Queue) )


# Synchronized [thread safe] version of the Queue Collection data structure:
#$queue = [System.Collections.Queue]::Synchronized( (New-Object System.Collections.Queue) )

<#

$servers | ForEach {
        $queue.Enqueue($_) | Out-Null
    }

#>

$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$RunspacePool.Open()
$Jobs = @()

1..10 | Foreach-Object {

}


#----------------------------------------------------------------------------------------------------
#--JOB BLOCK-----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

$JOB_BLOCK = {
    param($DIR_QUEUE, $JOB_LIST)
    Write-Host "DIR_NEXT: "+$DIR_NEXT+" | JOB_LIST: "+$JOB_LIST
    $DIR_ENUM = [System.IO.Directory]::EnumerateFileSystemEntries($DIR_QUEUE.Dequeue(), "*.*", "TopDirectoryOnly")
    foreach($FILE in $DIR_ENUM)
    {
        Write-Host $FILE
        #$DIR_QUEUE.Enqueue($FILE)
    }
}

#----------------------------------------------------------------------------------------------------
#--MAIN START----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

if ($USE_CURRENT_DIRECTORY -eq $true){
    $DIR_START = Get-Location
}

Write-Host $JOB_BLOCK

$DIR_QUEUE.Enqueue($DIR_START)

Write-Host ("DIR_START: "+$DIR_QUEUE.Peek())
Write-Host ("Count before loop: "+$DIR_QUEUE.Count)

while ($DIR_QUEUE.Count -gt 0)
{
    #Write-Host "Thread count: " $JOB_LIST.Count
    if ($JOB_LIST.Count -lt $MAX_JOBS)
    {
        Write-Host "Spawning thread: " $JOB_LIST.Count
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript({Start-Sleep 5})
        $Jobs += $PowerShell.BeginInvoke()
    }
    else
    {
        Write-Host "Waiting for job to finish..."
    }
}

while ($Jobs.IsCompleted -contains $false) {Start-Sleep -Milliseconds 100}

<#

$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$RunspacePool.Open()
$Jobs = @()

1..10 | Foreach-Object {
    $PowerShell = [powershell]::Create()
    $PowerShell.RunspacePool = $RunspacePool
    $PowerShell.AddScript({Start-Sleep 5})
    $Jobs += $PowerShell.BeginInvoke()
}
while ($Jobs.IsCompleted -contains $false) {Start-Sleep -Milliseconds 100}



$MaxThreads = 5
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$PowerShell = [powershell]::Create()
$PowerShell.RunspacePool = $RunspacePool
$RunspacePool.Open()
$PowerShell.AddScript({param ($Text) Write-Output $Text})
$PowerShell.AddArgument("Hello world!")
$PowerShell.BeginInvoke()


foreach ($file in $files) {
    $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
        $params = $using:file
        Invoke-WebRequest @params
    }
}

foreach ($job in $jobs) {
    Receive-Job -Job $job
}



#>