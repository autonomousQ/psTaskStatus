# psTaskStatus.ps1
# Query all scheduled tasks with "_" prefix

$results = @()
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '_*' -and $_.State -ne 'Disabled' }
foreach ($task in $tasks) {
    try {
        $info       = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
        $resultCode = $info.LastTaskResult
        $lastRun    = $info.LastRunTime
        $nextRun    = $info.NextRunTime
        $missed     = $info.NumberOfMissedRuns
    } catch {
        $resultCode = -1
        $lastRun    = $null
        $nextRun    = $null
        $missed     = 0
    }
    $lastResult = switch ($resultCode) {
        0          { 'Success (0x0)' }
        0x41301    { 'Currently Running (0x41301)' }
        0x41303    { 'Task Not Yet Run (0x41303)' }
        0x800710E0 { 'Terminated By User (0x800710E0)' }
        -1         { 'Error (query failed)' }
        default    { "Unknown (0x{0:X})" -f $resultCode }
    }
    $light = switch ($resultCode) {
        0       { 'GREEN'  }
        0x41301 { 'YELLOW' }
        default { 'RED'    }
    }
    $results += [PSCustomObject]@{
        Light          = $light
        TaskName       = $task.TaskName
        State          = $task.State
        NextRunTime    = $nextRun
        LastRunTime    = $lastRun
        LastResult     = $lastResult
        NumberOfMissed = $missed
    }
}
$results | Format-Table -AutoSize
Start-Sleep -Seconds 5