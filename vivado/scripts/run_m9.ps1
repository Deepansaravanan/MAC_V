[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$FpgaPart,
    [ValidateSet('mac_int8','mac_int16','reconfigurable_mac_top','reconfigurable_mac_optimized','mac_array_4lane')][string]$Top,
    [ValidateRange(0.001,100000.0)][double]$ClockPeriodNs = 10.000
)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$vivado = & (Join-Path $PSScriptRoot 'check_vivado.ps1') -Quiet
if ($LASTEXITCODE -ne 0 -or -not $vivado) { Write-Host 'M9 PARTIAL: Vivado unavailable; no results generated.' -ForegroundColor Yellow; exit 2 }
$tops = if ($Top) { @($Top) } else { @('mac_int8','mac_int16','reconfigurable_mac_top','reconfigurable_mac_optimized','mac_array_4lane') }
$rows = @()
foreach ($design in $tops) {
    $logDir = Join-Path $repoRoot "results\vivado\$design"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $log = Join-Path $logDir 'vivado.log'
    Write-Host "Running $design ..."
    & $vivado -mode batch -notrace -source (Join-Path $PSScriptRoot 'run_all.tcl') -tclargs $FpgaPart $design $ClockPeriodNs 2>&1 | Tee-Object -FilePath $log
    $ok = ($LASTEXITCODE -eq 0)
    $rows += [pscustomobject]@{ Architecture=$design; Flow=$(if($ok){'PASS'}else{'FAIL'}); Log=$log }
}
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    & $python.Source (Join-Path $repoRoot 'python\parse_vivado_reports.py') --root $repoRoot; $parseExit=$LASTEXITCODE
    & $python.Source (Join-Path $repoRoot 'python\generate_m9_plots.py') --root $repoRoot; $plotExit=$LASTEXITCODE
} else { Write-Warning 'Python unavailable; CSVs and plots skipped.'; $parseExit=1; $plotExit=1 }
$rows | Format-Table -AutoSize
$allPassed = ($rows.Where({$_.Flow -ne 'PASS'}).Count -eq 0) -and ($parseExit -eq 0)
Write-Host "CSV summaries: $(if($parseExit -eq 0){'generated'}else{'FAILED'})"
Write-Host "Plots: $(if($plotExit -eq 0){'generated where data exists'}else{'skipped/FAILED'})"
if ($allPassed -and -not $Top -and $rows.Count -eq 5) { Write-Host 'Overall M9 status: PASS'; exit 0 }
if ($allPassed -and $Top) { Write-Host 'Single-top status: PASS (run all five for M9 PASS)'; exit 0 }
Write-Host 'Overall M9 status: FAIL'; exit 1
