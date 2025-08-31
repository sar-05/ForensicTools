class apikey
{
    [Parameter(Mandatory=$true)][string]$Key
    [string]$ValidationUrl='https://api.abuseipdb.com/api/v2/check'

    ApiKey([string]$Key)
    {
        $this.Key = $Key
    }

    ApiKey([string]$Key, [string]$ValidationUrl)
    {
        $this.Key = $Key
        $this.ValidationUrl = $ValidationUrl
    }

    [bool]Validate()
    {
        try
        {
            $headers = @{
                Key = $this.Key
                Accept = 'application/json'
            }

            $query = @{
                # Whitelisted ABUSEIPDB IP
                ipAddress = '118.25.6.39'
                maxAgeInDays = 90
            }

            $response = Invoke-WebRequest -Uri $this.ValidationUrl -Headers $headers -Body $query -ErrorAction Stop
            $response.StatusDescription

            # Returns true only if StatusCode is 200
            return $response.StatusCode -eq 200
        } catch
        {
            Write-Warning "Validation of API Key failed: $($_.Exception.Message)"
            return $false
        }
    }
}
