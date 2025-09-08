function Test-IpList
{
<#
.SYNOPSIS
Tests a list of IP addresses against the AbuseIPDB API and exports results to
IpList.csv.

.DESCRIPTION
Test-IpList validates and tests multiple IP addresses using the Test-Ip helper.
When -Test is supplied, a small built-in sample list (including invalid entries)
is used; otherwise the IP list is retrieved from Get-NetworkProcess -ReturnIPList.
If -Menu is not supplied the function sets ErrorActionPreference to Stop.

.PARAMETER Test
Switch. Use a small built-in test list of IPs (includes invalid entries) instead
of retrieving real IPs.

.PARAMETER Menu
Switch. Indicates the function is being called from Select-ForensicTool menu.

.OUTPUTS
System.Object
An array of objects is returned and also displayed with Format-Table.
A CSV file IpList.csv is written with the results.

.EXAMPLE
PS> Test-IpList -Test
Runs the function against the built-in test IP list, exports IpList.csv, and displays the results.

.EXAMPLE
PS> Test-IpList
Retrieves the IP list from Get-NetworkProcess, tests each IP, exports IpList.csv
and displays the results.

.NOTES
Requires helper functions: Get-ApiKey, Get-NetworkProcess, and Test-Ip.
Ensure valid API credentials and network connectivity for AbuseIPDB calls.
#>
    param(
        [switch]$Test,
        [switch]$Menu
    )

    # Possibly imlplement a mechanism where error  action is stop if calling directly
    # But throw a different type of error to go back to the menu if calling from there
    if (-not $Menu)
    {
        $ErrorActionPreference='Stop'
    }

    if ($Test)
    {
        $IpList=@('136.34.156.82','Thisisabadtest','104.26.12.38','167.94.138.137')
    } else
    {
        $IpList=Get-NetworkProcess -ReturnIPList
    }

    $Results=@()

    if ($IpList.Count -eq 0)
    {
        Write-Warning "Empty IP list"
        return $null
    }

    try
    {
        $ApiKey=Get-ApiKey
    } catch [System.Net.Http.HttpRequestException]
    {
        Write-Error "Network error: $($_.Exception.Message)"
    } catch [System.InvalidOperationException]
    {
        Write-Error "Invalid operation: $($_.Exception.Message)"
    } catch
    {
        Write-Error "Unexpected error when the API Key: $_"
    }

    foreach ($Ip in $IpList)
    {
        try
        {
            # Parse will throw if InputString is not a valid IP address
            $Ip=[System.Net.IPAddress]::Parse($Ip)
            $Answer=Test-Ip -Ip $Ip -ApiKey $ApiKey
            $Results+=$Answer.data
        } catch [System.FormatException]
        {
            Write-Warning "Invalid format: $($_.Exception.Message)"
            continue
        } catch [System.ArgumentNullException]
        {
            Write-Warning "Input was null: $($_.Exception.Message)"
            continue
        } catch [System.InvalidOperationException]
        {
            Write-Error "Invalid operation: $($_.Exception.Message)"
        } catch [System.Net.Http.HttpRequestException]
        {
            Write-Error "Unable to connect to AbuseIPDB: $($_.Exception.Message)"
        } catch
        {
            Write-Error "Unexpected error when testing the IP list: $_"
        }
    }
    try
    {
        Write-Host "Savinig report to IpList.csv"
        $Results | Export-Csv -Path "IpList.csv" -NoTypeInformation
    }
    catch
    {
        Write-Warning "Unable to save results: $_"
    }
    return $Results | Format-Table
}
