function ApiKeyTest {
    param (
        [string]$ApiKey,
        [ipaddress]$TestIp='104.26.12.38',
        [uri]$Url='https://api.abuseipdb.com/api/v2/check',
        [int]$MaxAgeInDays=90
    )

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        throw [System.ArgumentException]::new("API key cannot be empty or whitespace.")
    }

    $Headers = @{ 'Key' = $ApiKey }
    $Querystring = @{
        'IpAddress' = $TestIp.ToString()
        'MaxAgeInDays' = $MaxAgeInDays.ToString()
    }

    Invoke-RestMethod -uri $UrlObj.ToString() -Method GET -Body $Querystring -Headers $Headers -ErrorAction Stop
}
