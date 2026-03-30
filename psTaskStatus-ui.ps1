# psTaskStatus-ui.ps1
# Query all scheduled tasks with "_" prefix
# Output: .\index.html

$outputPath = ".\index.html"
$results    = @()
$tasks      = Get-ScheduledTask | Where-Object { $_.TaskName -like '_*' -and $_.State -ne 'Disabled' }

foreach ($task in $tasks) {
    try {
        $info       = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
        $resultCode = $info.LastTaskResult
        $lastRun    = if ($info.LastRunTime) { $info.LastRunTime.ToString("MM/dd/yyyy hh:mm tt") } else { '-' }
        $nextRun    = if ($info.NextRunTime) { $info.NextRunTime.ToString("MM/dd/yyyy hh:mm tt") } else { '-' }
        $missed     = $info.NumberOfMissedRuns
    } catch {
        $resultCode = -1
        $lastRun    = '-'
        $nextRun    = '-'
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
    $light = if ($resultCode -eq 0) { 'GREEN' }
             elseif ($resultCode -eq 0x41301) { 'BLUE' }
             else { 'RED' }

    $results += [PSCustomObject]@{
        Light          = $light
        TaskName       = $task.TaskName
        State          = $task.State.ToString()
        NextRunTime    = $nextRun
        LastRunTime    = $lastRun
        LastResult     = $lastResult
        NumberOfMissed = $missed
    }
}

# ── build table rows ──
$tableRows = ""
foreach ($r in $results) {
    $dotClass = switch ($r.Light) {
        'GREEN' { 'dot-green' }
        'BLUE'  { 'dot-blue'  }
        'RED'   { 'dot-red'   }
    }
    $rowClass = if ($r.Light -eq 'RED') { ' class="row-fail"' } else { '' }

    $tableRows += @"
        <tr$rowClass>
          <td class="col-light"><span class="dot $dotClass"></span></td>
          <td>$($r.TaskName)</td>
          <td>$($r.State)</td>
          <td>$($r.NextRunTime)</td>
          <td>$($r.LastRunTime)</td>
          <td>$($r.LastResult)</td>
          <td class="col-missed">$($r.NumberOfMissed)</td>
        </tr>
"@
}

# ── summary counts ──
$totalTasks = $results.Count
$greenCount = @($results | Where-Object { $_.Light -eq 'GREEN' }).Count
$redCount   = @($results | Where-Object { $_.Light -eq 'RED'   }).Count
$blueCount  = @($results | Where-Object { $_.Light -eq 'BLUE'  }).Count
$timestamp  = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")

# ── write HTML ──
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="300">
<title>Automation Status</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;600;700&display=swap');

  :root {
    --bg:          #0e1117;
    --surface:     #161b22;
    --border:      #30363d;
    --text:        #e6edf3;
    --text-muted:  #8b949e;
    --green:       #2ea043;
    --green-glow:  rgba(46, 160, 67, 0.35);
    --red:         #da3633;
    --red-glow:    rgba(218, 54, 51, 0.35);
    --blue:        #388bfd;
    --blue-glow:   rgba(56, 139, 253, 0.35);
    --accent:      #58a6ff;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'IBM Plex Sans', sans-serif;
    background: var(--bg);
    color: var(--text);
    padding: 2rem;
    min-height: 100vh;
  }

  /* ── header ── */
  .header {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    margin-bottom: 1.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid var(--border);
  }
  .header h1 {
    font-size: 1.5rem;
    font-weight: 700;
    letter-spacing: -0.02em;
  }
  .header h1 span { color: var(--accent); }
  .timestamp {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 0.8rem;
    color: var(--text-muted);
  }

  /* ── summary cards ── */
  .summary {
    display: flex;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }
  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 1rem 1.5rem;
    min-width: 120px;
  }
  .card .label {
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
    margin-bottom: 0.3rem;
  }
  .card .value {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 1.8rem;
    font-weight: 600;
  }
  .card .value.green { color: var(--green); }
  .card .value.red   { color: var(--red);   }
  .card .value.blue  { color: var(--blue);  }

  /* ── table ── */
  .table-wrap {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 8px;
    overflow: hidden;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.85rem;
  }
  thead th {
    background: var(--bg);
    font-family: 'IBM Plex Mono', monospace;
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
    padding: 0.75rem 1rem;
    text-align: left;
    border-bottom: 1px solid var(--border);
  }
  tbody td {
    padding: 0.7rem 1rem;
    border-bottom: 1px solid var(--border);
    font-family: 'IBM Plex Mono', monospace;
    font-size: 0.8rem;
    white-space: nowrap;
  }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: rgba(255,255,255,0.02); }
  tr.row-fail { background: rgba(218, 54, 51, 0.06); }

  /* ── status dots ── */
  .col-light { width: 40px; text-align: center; }
  .dot {
    display: inline-block;
    width: 12px;
    height: 12px;
    border-radius: 50%;
  }
  .dot-green {
    background: var(--green);
    box-shadow: 0 0 8px var(--green-glow);
  }
  .dot-red {
    background: var(--red);
    box-shadow: 0 0 8px var(--red-glow);
    animation: pulse-red 2s infinite;
  }
  .dot-blue {
    background: var(--blue);
    box-shadow: 0 0 8px var(--blue-glow);
    animation: pulse-blue 1.5s infinite;
  }
  .col-missed { text-align: center; }

  @keyframes pulse-red {
    0%, 100% { box-shadow: 0 0 6px var(--red-glow); }
    50%      { box-shadow: 0 0 16px var(--red-glow); }
  }
  @keyframes pulse-blue {
    0%, 100% { box-shadow: 0 0 6px var(--blue-glow); }
    50%      { box-shadow: 0 0 16px var(--blue-glow); }
  }

  /* ── refresh button ── */
  .btn-refresh {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 0.75rem;
    color: var(--accent);
    background: transparent;
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 0.4rem 1rem;
    cursor: pointer;
    transition: background 0.2s, border-color 0.2s;
  }
  .btn-refresh:hover {
    background: rgba(88, 166, 255, 0.08);
    border-color: var(--accent);
  }
  .btn-refresh:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
  .btn-refresh .spinner {
    display: inline-block;
    width: 12px;
    height: 12px;
    border: 2px solid var(--border);
    border-top-color: var(--accent);
    border-radius: 50%;
    animation: spin 0.6s linear infinite;
    vertical-align: middle;
    margin-right: 6px;
  }
  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  /* ── footer ── */
  .footer {
    margin-top: 1rem;
    font-size: 0.7rem;
    color: var(--text-muted);
    text-align: right;
  }
</style>
</head>
<body>

<div class="header">
  <h1><span>&#9679;</span> Automation Status</h1>
  <div style="display: flex; align-items: center; gap: 1rem;">
    <button class="btn-refresh" id="btnRefresh" onclick="refreshStatus()">Refresh</button>
    <div class="timestamp">Last updated: $timestamp</div>
  </div>
</div>

<div class="summary">
  <div class="card">
    <div class="label">Total Tasks</div>
    <div class="value">$totalTasks</div>
  </div>
  <div class="card">
    <div class="label">Passing</div>
    <div class="value green">$greenCount</div>
  </div>
  <div class="card">
    <div class="label">Failing</div>
    <div class="value red">$redCount</div>
  </div>
  <div class="card">
    <div class="label">Running</div>
    <div class="value blue">$blueCount</div>
  </div>
</div>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th></th>
        <th>Task Name</th>
        <th>State</th>
        <th>Next Run</th>
        <th>Last Run</th>
        <th>Result</th>
        <th>Missed</th>
      </tr>
    </thead>
    <tbody>
$tableRows
    </tbody>
  </table>
</div>

<div class="footer">Auto-refresh every 5 minutes &bull; Source: Windows Task Scheduler</div>

<script>
async function refreshStatus() {
  var btn = document.getElementById('btnRefresh');
  btn.innerHTML = '<span class="spinner"></span>Refreshing...';
  btn.disabled = true;
  try {
    var res = await fetch('/api/status/refresh', { method: 'POST' });
    var data = await res.json();
    if (data.ok) {
      location.reload();
    } else {
      btn.textContent = 'Error - Retry';
      btn.disabled = false;
    }
  } catch (e) {
    btn.textContent = 'Error - Retry';
    btn.disabled = false;
  }
}
</script>

</body>
</html>
"@

# ── ensure output directory exists ──
$outputDir = Split-Path $outputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$html | Out-File -FilePath $outputPath -Encoding utf8 -Force

# ── console summary ──
$results | Format-Table -AutoSize
Write-Host ""
Write-Host "HTML written to: $outputPath" -ForegroundColor Cyan
Write-Host "Tasks: $totalTasks | Pass: $greenCount | Fail: $redCount | Running: $blueCount" -ForegroundColor Gray