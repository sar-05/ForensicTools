function Get-IpList {
    # Recieves an array object
    # Uses a for each to write-output so it can be piped to another function
    # param (
    #     [array]$Iplist
    # )
    $IpList = @('81.70.196.159', '206.168.34.75')

    foreach ($ip in $IpList){
            Write-Output $ip
        }
}

