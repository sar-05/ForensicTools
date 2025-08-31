function Test-IpList
{
    param(
        [switch]$Test
    )

    if ($Test)
    {
        $IpList=@('136.34.156.82','14.103.45.20','104.26.12.38','167.94.138.137')
    } else
    {
        $IpList=Get-NetworkProcess -ReturnIPList
    }

    $Results=@()

    foreach ($Ip in $IpList)
    {
        try
        {
            $Answer=Test-Ip $Ip
            $Results+=$Answer.data
        } catch
        {
            Write-Error "Unable to keep testing the IP List: $_" -ErrorAction Stop
        }
    }
    return $Results
}
