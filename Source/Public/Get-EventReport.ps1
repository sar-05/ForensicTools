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
