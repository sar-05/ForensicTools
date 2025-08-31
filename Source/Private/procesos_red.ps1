# Obtiene los procesos activos con path no nulo
$procesos = Get-Process | Where-Object {$_.Path -ne $null} | Select-Object Id, ProcessName, Path

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
    if($proc)
    {
        [PSCustomObject]@{
            ProcessName   = $process_con.ProcessName
            PID           = $process_con.Id
            Path          = $process_con.Path
            LocalAddress  = $elemento.LocalAddress
            LocalPort     = $elemento.LocalPort
            RemoteAddress = $elemento.RemoteAddress
            RemotePort    = $elemento.RemotePort
            State         = $elemento.State

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
                ProcessName   = $elemento.ProcessName
                PID           = $elemento.Id
                Path          = $elemento.Path
                Signature     = $elemento.Status

            }
        }
    } catch
    {
        [PSCustomObject]@{
            ProcessName   = $elemento.ProcessName
            PID           = $elemento.Id
            Path          = $elemento.Path
            Signature     = "Error al verificar"
        }
    }

}
# Impresión de la tabla de procesos con firma No Valida
Write-Host "TABLA DE PROCESOS SOSPECHOSOS"
$procesos_sospechosos | Format-Table -AutoSize

Write-Host "-------------------------------------------------------------------"
Write-Host "FIN DE BUSQUEDA DE PROCESOS SOSPECHOSOS"
Write-Host "-------------------------------------------------------------------"
