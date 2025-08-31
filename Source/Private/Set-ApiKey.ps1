function Set-ApiKey
{
    param (
        [int] $MaxRetries = 3
    )

    $Attempts = 0

    do
    {
        $Attempts++
        try
        {
            $Key = Read-Host -Prompt "Set the AbuseIPDB API Key: "
            $ApiKey = [apikey]::new($Key)
            if ($ApiKey.Validate())
            {
                $env:ABUSEIPDB_API_KEY = $ApiKey.Key
                return $ApiKey.Key

            }
        } catch
        {
            Write-Error "Unable to set API Key: $_"
        }
    } while ($Attempts -lt $MaxRetries)

    throw [System.InvalidOperationException]::new("Max attempts of setting the API Key reached.")
}
