[CmdletBinding()]
param([switch]$Quiet)
$candidate = Get-Command vivado -ErrorAction SilentlyContinue
if (-not $candidate) {
    foreach ($root in @('C:\AMDDesignTools', 'C:\Xilinx\Vivado', 'C:\AMD\Vivado')) {
        if (Test-Path -LiteralPath $root) {
            $candidate = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                ForEach-Object {
                    @(
                        (Join-Path $_.FullName 'Vivado\bin\vivado.bat'),
                        (Join-Path $_.FullName 'bin\vivado.bat')
                    )
                } | Where-Object { Test-Path -LiteralPath $_ } |
                Sort-Object -Descending | Select-Object -First 1
            if ($candidate) { break }
        }
    }
}
if (-not $candidate) {
    if (-not $Quiet) {
        Write-Host 'Vivado was not found on PATH or under C:\AMDDesignTools / C:\Xilinx\Vivado / C:\AMD\Vivado.' -ForegroundColor Yellow
        Write-Host 'Install AMD Vivado with device support, then add its bin directory to PATH.'
    }
    exit 1
}
$vivadoPath = if ($candidate -is [string]) { $candidate } elseif ($candidate.Source) { $candidate.Source } else { $candidate.FullName }
if (-not $Quiet) { Write-Host "Vivado executable: $vivadoPath"; & $vivadoPath -version | Select-Object -First 2 }
$vivadoPath
exit 0
