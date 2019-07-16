Function Export-WirelessNetworkProfile {
    Param (
        $SSID,
        $Path = $PWD,
        [Switch]$MaskPassword = $false
    )
    IF ($SSID.GetType().Name -eq "PSCustomObject") {
        $ssidName = $SSID.SSID
    } ELSEIF ($SSID.GetType().Name -eq "String") {
        $SSID = Get-AvailableWirelessNetworks -SSID $SSID
        $ssidName = $SSID.SSID
    }
    IF ($MaskedPassword) {
        netsh wlan export profile name=$ssidName folder="$Path"
    } ELSE {
        netsh wlan export profile name=$ssidName folder="$Path" key=clear
    }
}

Function Import-WirelessNetworkProfile {
    Param (
        $Profile
    )
    netsh wlan add profile filename="$Profile"
}

Function Get-AvailableWirelessNetworks {
    Param (
        $SSID
    )
    $response = netsh wlan show networks mode=bssid
    $wLANs = $response | Where-Object {$_ -match "^SSID"} | Foreach-Object {
        $report = "" | Select SSID,NetworkType,Authentication,Encryption
        $i = $response.IndexOf($_)
        $report.SSID = $_ -replace "^SSID\s\d+\s:\s",""
        $report.NetworkType = $response[$i+1].Split(":")[1].Trim()
        $report.Authentication = $response[$i+2].Split(":")[1].Trim()
        $report.Encryption = $response[$i+3].Split(":")[1].Trim()
        $report
    }
    IF ($SSID) {
        $wLANs | Where-Object {$_.SSID -eq $SSID}
    } ELSE {
        $wLANs
    }
}

Function ConnectTo-WirelessNetwork {
    Param (
        $SSID
    )
    IF ($SSID.GetType().Name -eq "PSCustomObject") {
        $ssidName = $SSID.SSID
    } ELSEIF ($SSID.GetType().Name -eq "String") {
        $SSID = Get-AvailableWirelessNetworks -SSID $SSID
        $ssidName = $SSID.SSID
    }
    $wlanProfile = netsh wlan show profiles name=$ssidName
    IF ($wlanProfile -eq ('Profile "' + $ssidName + '" is not found on the system.')) {
        Write-Host "New Wireless Network detected.  Not yet supported" -ForegroundColor Red
    }
    netsh wlan connect ssid=$ssidName name=$ssidName
}

Function Get-WirelessNetworkProfiles {
    Param (
        $SSID
    )
    IF ($SSID) {
        IF ($SSID.GetType().Name -eq "PSCustomObject") {
            $ssidName = $SSID.SSID
        } ELSEIF ($SSID.GetType().Name -eq "String") {
            $SSID = Get-AvailableWirelessNetworks -SSID $SSID
            $ssidName = $SSID.SSID
        }
        netsh wlan show profiles name="$ssidName"
    } ELSE {
        netsh wlan show profiles
    }
}