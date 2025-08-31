function TestIpList {
    param(
    [bool]$IsTest=$false
    )

    if ($IsTest){
        $IpList=@(136.34.156.82,14.103.45.20,104.26.12.38,167.94.138.137)
    } else {
        $IpList=Get-NetworkProcess -ReturnIpList True
    }
    $ResponseList=@()

    if (-not $IpList) {
        $IpList=Get-IpList
    }

    foreach ($Ip in $IpList){
        $ResponseList+=Test-Ip $Ip
    }
}
