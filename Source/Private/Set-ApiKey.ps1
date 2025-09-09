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
            $Key = Read-Host -AsSecureString -Prompt "Set the AbuseIPDB API Key"
            $ApiKey = [apikey]::new($Key)
            if ($ApiKey.Validate())
            {
                $env:ABUSEIPDB_API_KEY = $ApiKey.ToString()
                return $ApiKey.ToString()

            }
            # Validation fails when status code isn't 200
            throw [System.FormatException]::new("API Key failed validation")
        } catch
        {
            Write-Warning "Unable to set API Key: $_"
        }
    } while ($Attempts -lt $MaxRetries)

    throw [System.InvalidOperationException]::new("Max attempts of setting the API Key reached.")
}
