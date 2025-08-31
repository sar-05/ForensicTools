class apikey
{
    [Parameter(Mandatory=$true)][securestring]$Key
    [string]$ValidationUrl='https://api.abuseipdb.com/api/v2/check'

    ApiKey([securestring]$Key)
    {
        $this.Key = $Key
    }

    ApiKey([string]$Key, [string]$ValidationUrl)
    {
        $this.Key = $Key
        $this.ValidationUrl = $ValidationUrl
    }

    [string]ToString()
    {
        return ConvertFrom-SecureString -SecureString $this.Key -AsPlainText
    }

    [bool]Validate()
    {
        try
        {
            $headers = @{
                Key = $this.ToString()
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
            # Only throw if network is unreachable
        } catch [System.Net.Http.HttpRequestException]
        {
            Write-Error "Unable to verify API Key: $_"
            throw
        } catch
        {
            Write-Warning "Validation of API Key failed: $($_.Exception.Message)"
            return $false
        }
    }
}
