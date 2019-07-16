Function Create-WirelessNetworkProfile {
    Param (
        $SSID,
        $Authentication = "WPA2PSK",
        [Parameter(Mandatory,DontShow)][SecureString]$PassPhrase
    )
    IF ($SSID.GetType().Name -eq "PSCustomObject") {
        $ssidName = $SSID.SSID
    } ELSEIF ($SSID.GetType().Name -eq "String") {
        $SSID = Get-AvailableWirelessNetworks -SSID $SSID
        $ssidName = $SSID.SSID
    }
    $sampleProfile = [xml]@"
<?xml version="1.0" encoding="UTF-8"?>
<WLANProfile xmlns="https://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssidName</name>
    <SSIDConfig>
        <SSID>
            <name>$ssidName</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <autoSwitch>false</autoSwitch>
    <MSM>
        <security>
            <authEncryption>
                <authentication>$Authentication</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial> <!-- insert key here --> </keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
    $tmpFileName = "$($env:temp)\sampleProfile.xml"
    $sampleProfile.Save($tempFileName)
    add profile filename=$tempFileName user=current
    Remove-Item -Path $tempFileName -Force
    $UnsecurePassword = (New-Object PSCredential "user",$Password).GetNetworkCredential().Password
    netsh wlan set profileparameter name=$ssidName keyMaterial=$UnsecurePassword
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

<# NOTES
netsh wlan set profileparameter name=$ssidName SSIDname=$ssidName autoSwitch=no ConnectionMode=auto Randomization=no authentication=WPA2PSK encryption=AES keyType=passphrase keyMaterial=$pwd

netsh wlan set profileparameter /?

Usage: set profileparameter [name=]<string> [[interface=]<string>]
       [SSIDname=<string>] [ConnectionType=ESS|IBSS] [autoSwitch=yes|no]
       [ConnectionMode=auto|manual] [nonBroadcast=yes|no]
       [Randomization=[yes|no|daily]]
       [authentication=open|shared|WPA|WPA2|WPAPSK|WPA2PSK]
       [encryption=none|WEP|TKIP|AES] [keyType=networkKey|passphrase]
       [keyIndex=1-4] [keyMaterial=<string>] [PMKCacheMode=yes|no]
       [PMKCacheSize=1-255] [PMKCacheTTL=300-86400] [preAuthMode=yes|no]
       [preAuthThrottle=1-16 [FIPS=yes|no]
       [useOneX=yes|no] [authMode=machineOrUser|machineOnly|userOnly|guest]
       [ssoMode=preLogon|postLogon|none] [maxDelay=1-120]
       [allowDialog=yes|no] [userVLAN=yes|no]
       [heldPeriod=1-3600] [AuthPeriod=1-3600] [StartPeriod=1-3600]
       [maxStart=1-100] [maxAuthFailures=1-100] [cacheUserData = yes|no]
       [cost=default|unrestricted|fixed|variable]

#>