function Test-IpList
{
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
    return $Results
}
