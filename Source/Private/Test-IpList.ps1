function TestIpList {
    param (
    [array]$IpList
    )

    $ResponseList=@()

    if (-not $IpList) {
        $IpList=Get-IpList
    }

    foreach ($Ip in $IpList){
        $ResponseList+=Test-Ip $Ip
    }
}
