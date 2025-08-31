function Test-Ip
{
    param (
        [Parameter(Mandatory=$true)][ipaddress]$Ip,
        [string]$ApiKey,
        [string]$Url='https://api.abuseipdb.com/api/v2/check',
        [int]$MaxAgeInDays=90
    )

    $Query = @{
        ipAddress = $Ip.ToString()
        maxAgeInDays = 90
    }

    $Headers = @{
        Key    = $ApiKey
        Accept = 'application/json'
    }

    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Body $Query
    return $Response
}
