Set-StrictMode -Version Latest

function Get-NetworkProcess {
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
    [bool]$ReturnIPList
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

    Write-Host "-------------------------------------------------------------------"
    Write-Host "ASOCIANDO LOS PROCESOS CON CONEXIONES..."
    Write-Host "-------------------------------------------------------------------"

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


    Write-Host "TABLA DE CONEXIONES"

    $asociacion | Format-Table -AutoSize
    # Filtra las ip's unicas de los procesos asociados
    $arreglo_unico = $arreglo_ip | Sort-Object | Get-Unique

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
                                                                                Ruta = $_.Ruta } }
    $informe_csv_2 | Export-Csv -Path "$env:USERPROFILE\Desktop\procesos_sospechosos.csv" -NoTypeInformation

    Write-Host "-------------------------------------------------------------------"
    Write-Host "FIN DE BUSQUEDA DE PROCESOS SOSPECHOSOS"
    Write-Host "-------------------------------------------------------------------"

    if ($ReturnIPList){
        return $arreglo_ip
    }
}
