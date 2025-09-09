Set-StrictMode -Version Latest

function Select-ForensicTool {

    $Prompt="Select an option:
    1) Get-EventReport
    2) Get-NetworkProcess
    3) Test-IpList
    4) Exit

    Your Selection"

    while ($true) {
        Write-Host ""
        Write-Host $Prompt -NoNewline
        $selection = Read-Host " "
        switch ($selection.Trim()) {
            '1' {
                Get-EventReport
            }
            '2' {
                Get-NetworkProcess
            }
            '3' {
                Test-IpList
            }
            '4' {
                exit
            }
            default {
                Write-Warning "Invalid selection. Please enter 1, 2, or 3."
            }
        }
    }
}
