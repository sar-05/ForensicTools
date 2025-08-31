function Get-ApiKey
{
    param ()

    $ApiKey = $env:ABUSEIPDB_API_KEY
    if ($ApiKey)
    {
        return $ApiKey
    }

    return Set-ApiKey
}

