function Test-Ip
{
    param (
        [string]$Ip='104.26.12.38',
        [string]$Url='https://api.abuseipdb.com/api/v2/check',
        [int]$MaxAgeInDays=90
    )

    if (-not [System.Net.IPAddress]::TryParse($Ip, [ref]$IpObj)) {
        throw [System.ArgumentException]::new("Parameter $Ip is not a valid IP address")
    }

    if (-not [System.Uri]::TryParse($Url, [ref]$UrlObj)) {
        throw [System.ArgumentException]::new("Parameter $Url is not a valid Url address")
    }

    try {
      $ApiKey = Get-ApiKey
    } catch {
      Write-Error "Get-ApiKey failed: $($_.Exception.Message)"
      throw
    }

    $Headers = @{ 'Key' = $ApiKey }
    $Querystring = @{
        'IpAddress' = $IpObj.ToString()
        'MaxAgeInDays' = $MaxAgeInDays.ToString()
    }

    try {
        $Response = Invoke-RestMethod -uri $UrlObj.ToString() -Method GET -Body $Querystring -Headers $Headers -ErrorAction Stop
        return $Response
    } catch [System.Net.WebException] {
        Write-Error "HTTP/Network error: $($_.Exception.Status) - $($_.Exception.Message)"
        throw
    } catch [System.Threading.Tasks.TaskCanceledException] {
        Write-Error "Request timed out or cancelled."
    } catch {
        Write-Error "Error checking IP $Ip in databse: $($_.Exception.GetType().FullName) - $($_.Exception.Message)"
    }
}
