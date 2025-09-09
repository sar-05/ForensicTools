#Region './Classes/apikey.ps1' -1

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
#EndRegion './Classes/apikey.ps1' 54
#Region './Private/Get-ApiKey.ps1' -1

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
#EndRegion './Private/Get-ApiKey.ps1' 13
#Region './Private/Set-ApiKey.ps1' -1

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
#EndRegion './Private/Set-ApiKey.ps1' 32
#Region './Private/Test-Ip.ps1' -1

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
#EndRegion './Private/Test-Ip.ps1' 23
#Region './Public/Get-EventReport.ps1' -1

function Get-EventReport(){
     <#
    .SYNOPSIS
        Extrae y exporta eventos relevantes del Visor de eventos de Windows.
    .DESCRIPTION
        Filtra registros de eventos por log (Seguridad, Sistema, Aplicación), por fecha
        y detecta eventos sospechosos relacionados con seguridad.
        Exporta resultados a CSV de manera organizada.
    .PARAMETER Days
        Número de días hacia atrás desde la fecha actual para filtrar eventos.
    .PARAMETER MaxEvents
        Número máximo de eventos a recuperar por log.
    .PARAMETER ExportPath
        Ruta base para exportar resultados. Si no se indica, se genera automáticamente en el Escritorio.
    .EXAMPLE
        Get-EventReport -Days 2 -MaxEvents 200 -ExportPath "C:\Reportes\eventos.csv"
    #>

     param (
        [int]$Days = 1,
        [int]$MaxEvents = 500,
        [string]$ExportPath
    )

    $startDate = (Get-Date).AddDays(-$Days)
    if (-not $ExportPath) {
        $ExportPath = "$env:USERPROFILE\Desktop\eventos_$((Get-Date).ToString('yyyyMMdd_HHmm')).csv"
    }
    $LogName=("Security", "System", "Application")


    # 1. Obtener eventos de los logs principales
    $events = foreach ($log in $LogName) {
        Get-WinEvent -FilterHashtable @{LogName=$log; Level=2,3} -MaxEvents $MaxEvents -ErrorAction SilentlyContinue |
        Where-Object { $_.TimeCreated -ge $startDate } |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message, @{Name="LogName";Expression={$log}}
    }


    #Identificar eventos sospechosos
    $suspectIds = @{
            4625 = "Intento de inicio de sesión fallido"
            4624 = "Inicio de sesión exitoso"
            4720 = "Creación de cuenta de usuario"
            4722 = "Cuenta de usuario habilitada"
            4724 = "Intento de restablecer contraseña de cuenta"
            4726 = "Eliminación de cuenta de usuario"
            4738 = "Cambio en membresía de grupo"
            1102 = "Limpieza del log de seguridad"
            104 = "Log de aplicación borrado"
            6005 = "Servicio de registro de eventos iniciado"
            6006 = "Servicio de registro de eventos detenido"
            1074 = "Apagado/Reinicio del sistema iniciado por usuario"
        }
    $suspicious = $events | Where-Object { $_.Id -in $suspectIds}

    #Mostrar los resultados
    if ($events) {
        Write-Host "`n=== Eventos generales ===" -ForegroundColor Green
        $events | Format-Table TimeCreated, Id, LevelDisplayName, ProviderName, LogName -AutoSize
    } else {
        Write-Host "No se encontraron eventos generales en el rango indicado." -ForegroundColor Yellow
    }

    if ($suspicious) {
        Write-Host "`n=== Eventos SOSPECHOSOS detectados ===" -ForegroundColor Red
        $suspicious | Format-Table TimeCreated, Id, Message -Wrap -AutoSize
    } else {
        Write-Host "`nNo se detectaron eventos sospechosos." -ForegroundColor Yellow
    }

    #Exportar Resultados
    $events | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nEventos exportados en: $ExportPath"

    if ($suspicious){
        $susExport = $ExportPath -replace ".csv","_sospechosos.csv"
        $suspicious | Export-Csv -Path $susExport -NoTypeInformation -Encoding UTF8
        Write-Host "`nEventos sospechosos exportados en: $suspExport" -ForegroundColor Red
    }
}
#EndRegion './Public/Get-EventReport.ps1' 82
#Region './Public/Get-NetworkProcess.ps1' -1

function Get-NetworkProcess
{
    #Set-StrictMode -Off
    <#
.SYNOPSIS
Obtiene los procesos sospechosos que tienen conexion a internet para obtener las IP relacionadas a esos procesos y detectar si se trata de un proceso sospechoso.
Tambien obtiene los procesos no firmados.

.DESCRIPTION
Esta funcin busca de entre los procesos sospechosos que tengan conexion a internet para identificar si son un proceso sospechoso, además de los procesos
con conexion, identifica aquellos procesos que no esten firmados por grupos verificados.

.EXAMPLE
Get-NetworkProcess

.NOTES
Puede ayudar identificar anomalias que esten corriendo en el equipo, ayudando a auditorias que requieran evaluar equipos con actividades sospechosas.
#>
    param(
        [switch]$ReturnIPList
    )
    # Obtiene los procesos activos con path no nulo
    $procesos = Get-Process | Where-Object { $null -ne $_.Path} | Select-Object Id, ProcessName, Path

    # Obtiene los procesos con conexiones a internet activas
    $conexiones = Get-NetTCPConnection |
        Where-Object {$_.State -eq "Established" -or $_.State -eq "Listen"} |
        Select-Object OwningProcess,
        LocalAddress,
        LocalPort,
        RemoteAddress,
        RemotePort,
        State


    if (-not $ReturnIPList)
    {
        Write-Host "-------------------------------------------------------------------"
        Write-Host "ASOCIANDO LOS PROCESOS CON CONEXIONES..."
        Write-Host "-------------------------------------------------------------------"

    }

    $arreglo_ip = @()

    # Relaciona las id's de los procesos activos con las id's con conexiones activas a internet
    # Además crea un objeto con los datos del proceso asociado
    $asociacion = foreach($elemento in $conexiones)
    {
        $process_con = $procesos | Where-Object {$_.Id -eq $elemento.OwningProcess}
        if($process_con)
        {
            [PSCustomObject]@{
                Nombre           = $process_con.ProcessName
                PID              = $process_con.Id
                Ruta             = $process_con.Path
                Direccion_Local  = $elemento.LocalAddress
                Puerto_Local     = $elemento.LocalPort
                Direccion_Remota = $elemento.RemoteAddress
                Puerto_Remoto    = $elemento.RemotePort
                Estado           = $elemento.State

            }
            $arreglo_ip += $elemento.RemoteAddress
        }

    }



    if (-not $ReturnIPList)
    {
        Write-Host "TABLA DE CONEXIONES"
        $asociacion | Format-Table -AutoSize
    }
    # Filtra las ip's unicas de los procesos asociados
    $arreglo_unico = $arreglo_ip | Sort-Object | Get-Unique

    if (-not $ReturnIPList)
    {
        Write-Host "ARREGLO DE IP'S: "
        Write-Host $arreglo_unico -Separator ", "

        $informe_csv = $arreglo_unico | ForEach-Object { [PSCustomObject]@{Ip = $_} }
        $informe_csv | Export-Csv -Path "$env:USERPROFILE\Desktop\ips_sospechosas.csv" -NoTypeInformation

        Write-Host "-------------------------------------------------------------------"
        Write-Host "FIN DE ASOCIACION DE PROCESOS CON CONEXIONES"
        Write-Host "-------------------------------------------------------------------"
        Write-Host "`n"
        Write-Host "-------------------------------------------------------------------"
        Write-Host "BUSQUEDA DE PROCESOS SOSPECHOSOS..."
        Write-Host "-------------------------------------------------------------------"

        # Obtiene los datos de la firma digital y compara si la firma es valida
        # para cada proceso que se obtuvo anteriormente

        $procesos_sospechosos = foreach($elemento in $procesos)
        {
            try
            {
                $firma = Get-AuthenticodeSignature -FilePath $elemento.Path

                if($firma.Status -ne "Valid")
                {
                    [PSCustomObject]@{
                        Nombre   = $elemento.ProcessName
                        PID      = $elemento.Id
                        Ruta     = $elemento.Path
                        Firma    = $elemento.Status

                    }
                }
            } catch
            {
                [PSCustomObject]@{
                    Nombre   = $elemento.ProcessName
                    PID      = $elemento.Id
                    Ruta     = $elemento.Path
                    Firma    = "Error al verificar"
                }
            }

        }
        # Impresión de la tabla de procesos con firma No Valida
        Write-Host "TABLA DE PROCESOS SOSPECHOSOS"
        $procesos_sospechosos | Format-Table -AutoSize
        $informe_csv_2 = $procesos_sospechosos | ForEach-Object { [PSCustomObject]@{Proceso = $_.Nombre
                Ruta = $_.Ruta
            } }
        $informe_csv_2 | Export-Csv -Path "$env:USERPROFILE\Desktop\procesos_sospechosos.csv" -NoTypeInformation

        Write-Host "-------------------------------------------------------------------"
        Write-Host "FIN DE BUSQUEDA DE PROCESOS SOSPECHOSOS"
        Write-Host "-------------------------------------------------------------------"
    }

    if ($ReturnIPList)
    {
        Write-Host $arreglo_ip
        return $arreglo_ip
    }
}
#EndRegion './Public/Get-NetworkProcess.ps1' 144
#Region './Public/Select-ForensicTool.ps1' -1

function Select-ForensicTool {

    $Prompt="Select an option:
    1) Get-EventReport
    2) Get-NetworkProcess
    3) Test-IpList
    4) Exit

    Your Selection"

    while ($true) {
        Write-Host ""
        Write-Host $Prompt -NoNewline
        $selection = Read-Host " "
        switch ($selection.Trim()) {
            '1' {
                Get-EventReport
            }
            '2' {
                Get-NetworkProcess
            }
            '3' {
                Test-IpList
            }
            '4' {
                exit
            }
            default {
                Write-Warning "Invalid selection. Please enter 1, 2, or 3."
            }
        }
    }
}
#EndRegion './Public/Select-ForensicTool.ps1' 34
#Region './Public/Test-IpList.ps1' -1

function Test-IpList
{
<#
.SYNOPSIS
Tests a list of IP addresses against the AbuseIPDB API and exports results to
IpList.csv.

.DESCRIPTION
Test-IpList validates and tests multiple IP addresses using the Test-Ip helper.
When -Test is supplied, a small built-in sample list (including invalid entries)
is used; otherwise the IP list is retrieved from Get-NetworkProcess -ReturnIPList.
If -Menu is not supplied the function sets ErrorActionPreference to Stop.

.PARAMETER Test
Switch. Use a small built-in test list of IPs (includes invalid entries) instead
of retrieving real IPs.

.PARAMETER Menu
Switch. Indicates the function is being called from Select-ForensicTool menu.

.OUTPUTS
System.Object
An array of objects is returned and also displayed with Format-Table.
A CSV file IpList.csv is written with the results.

.EXAMPLE
PS> Test-IpList -Test
Runs the function against the built-in test IP list, exports IpList.csv, and displays the results.

.EXAMPLE
PS> Test-IpList
Retrieves the IP list from Get-NetworkProcess, tests each IP, exports IpList.csv
and displays the results.

.NOTES
Requires helper functions: Get-ApiKey, Get-NetworkProcess, and Test-Ip.
Ensure valid API credentials and network connectivity for AbuseIPDB calls.
#>
    param(
        [switch]$Test,
        [switch]$Menu
    )

    # Possibly imlplement a mechanism where error  action is stop if calling directly
    # But throw a different type of error to go back to the menu if calling from there
    if (-not $Menu)
    {
        $ErrorActionPreference='Stop'
    }

    if ($Test)
    {
        $IpList=@('136.34.156.82','Thisisabadtest','104.26.12.38','167.94.138.137')
    } else
    {
        $IpList=Get-NetworkProcess -ReturnIPList
    }

    $Results=@()

    if ($IpList.Count -eq 0)
    {
        Write-Warning "Empty IP list"
        return $null
    }
    else
    {
        Write-Host "El arreglo es: $IpList"
    }

    try
    {
        $ApiKey=Get-ApiKey
    } catch [System.Net.Http.HttpRequestException]
    {
        Write-Error "Network error: $($_.Exception.Message)"
    } catch [System.InvalidOperationException]
    {
        Write-Error "Invalid operation: $($_.Exception.Message)"
    } catch
    {
        Write-Error "Unexpected error when the API Key: $_"
    }

    foreach ($String in $IpList)
    {
        try
        {
            # Parse will throw if InputString is not a valid IP address
            $Ip=[System.Net.IPAddress]::Parse($String)
            $Answer=Test-Ip -Ip $Ip -ApiKey $ApiKey
            $Results+=$Answer.data
        } catch [System.FormatException]
        {
            Write-Warning "Invalid format: $($_.Exception.Message)"
            continue
        } catch [System.ArgumentNullException]
        {
            Write-Warning "Input was null: $($_.Exception.Message)"
            continue
        } catch [System.InvalidOperationException]
        {
            Write-Error "Invalid operation: $($_.Exception.Message)"
        } catch [System.Net.Http.HttpRequestException]
        {
            Write-Error "Unable to connect to AbuseIPDB: $($_.Exception.Message)"
        } catch
        {
            Write-Error "Unexpected error when testing the IP list: $_"
        }
    }
    try
    {
        Write-Host "Savinig report to IpList.csv"
        $Results | Export-Csv -Path "IpList.csv" -NoTypeInformation
    }
    catch
    {
        Write-Warning "Unable to save results: $_"
    }
    return $Results | Format-Table
}
#EndRegion './Public/Test-IpList.ps1' 123
