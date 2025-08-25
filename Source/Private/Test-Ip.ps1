function Test-Ip
{
    <# Recieves Ip as a string, Checks uses AbusIPDB to get data in json format #>
    param (
        [string]$Ip
    )

    $querystring = @{
        'ipAddress' = $Ip
        'maxAgeInDays' = '90'
    }
    $url = 'https://api.abuseipdb.com/api/v2/check'
    $headers = @{ 'Key' = '' }
    $response = Invoke-RestMethod -uri $url -Method GET -Body $querystring -Headers $headers

    $response | ConvertTo-Json -Depth 10 | Write-Output
}
