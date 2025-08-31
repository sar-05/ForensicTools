function Set-ApiKey {
    param(
        [int] $MaxRetries = 3
    )

    $Attempts = 0

    do {
        $Attempts++

        try {
            $ApiKey = Read-Host -Prompt "Set the AbuseIPDB API Key"
            ApiKeyTest $ApiKey
            $env:ABUSEIPDB_API_KEY = $ApiKey
            return $ApiKey

        } catch [System.Net.WebException] {
            Write-Error "HTTP/Network error: $($_.Exception.Status) - $($_.Exception.Message)"
            throw
        } catch [System.ArgumentException] {
            Write-Warning "Invalid API key: $_"
        } catch [System.InvalidOperationException] {
            Write-Warning "API key validation failed: $_"
        } catch [System.Threading.Tasks.TaskCanceledException] {
            Write-Error "Api key validation request cancelled."
        } catch {
            Write-Error "Unexpected error when setting API key: $_"
            throw
        }

    } while ($Attempts -lt $MaxRetries)

    throw [System.InvalidOperationException]::new("Max amount of attempts reached.")
}
