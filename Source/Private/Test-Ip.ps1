function Test-Ip
{
    param (
        [Parameter(Mandatory=$true)][string]$Ip,
        [string]$Url='https://api.abuseipdb.com/api/v2/check',
        [int]$MaxAgeInDays=90
    )

    try
    {
        # Parse will throw if InputString is not a valid IP address
        # Recover original string type, but parsed
        $Ip= ([System.Net.IPAddress]::Parse($Ip)).ToString()
        $ApiKey = Get-ApiKey
    } catch
    {
        Write-Error "Unable to parse any IP: $_"
        throw #consider just setting error action to stop
    }


    $Query = @{
        # Whitelisted ABUSEIPDB IP
        ipAddress = $Ip
        maxAgeInDays = 90
    }

    $Headers = @{
        Key    = $ApiKey
        Accept = 'application/json'
    }

    try
    {
        $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Body $Query
        return $Response
    } catch
    {
        "Unexpected error: $($_.Exception.GetType().FullName) - $($_.Exception.Message)"
    }
}
