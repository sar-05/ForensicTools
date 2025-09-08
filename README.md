# ForensicTools

## Description

This PowerShell module includes four functions meant to help in the process of
auditing a Windows PC:

- Get-EventReport
  - Extracts and exports relevant events from the Windows Event Logs.
- Get-NetworkProcess
  - Gets suspicious processes that have an internet connection to obtain their IPs
  - Also catches unsigned processes.
- Test-IpList
  - Recives a list of IPs and uses AbuseIPDB to return critical information
    about their origin and danger.

## Installation

Simply copy the contents of Output to a directory in the `PSModulePath`, for
example:

```posh
Copy-Item -Recurse "./Output/ForensicTools" "~/Documents/PowerShell/Modules"
```
