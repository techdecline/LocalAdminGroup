<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Get-ADRemoteAdminGroupMember {
    [CmdletBinding()]
    param (
        [String]$ComputerName
    )
    invoke-command -ComputerName $ComputerName -ScriptBlock {
        function GetLocalAdminGroupMember {
            param ([String]$Platform)
            #$adminRegex = "^S-1-5-21.*-500$"
            $domadminRegex = "^S-1-5-21.*-512"
            $adminArr = [System.Collections.ArrayList]@()
            if ($Platform -eq "W10") {
                Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object {$_.PrincipalSource -eq "ActiveDirectory" -and $_.SID -notmatch $domadminRegex} | ForEach-Object {$adminArr.Add($_.Name)} | Out-Null
            }
            elseif ($Platform -eq "W7") {
                Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object {($_.Name -split "\\")[0] -eq $env:USERDOMAIN -and $_.SID -notmatch $domadminRegex } | ForEach-Object {$adminArr.Add($_.Name)} | Out-Null
            }
            if ($adminArr) {
                return $adminArr
            }
            else {
                return $null
            }
        }

        $osVersion = (Get-WmiObject -Class win32_operatingsystem -Property Caption).Caption
        switch -regex ($osVersion) {
            "^Microsoft Windows 10.*" {
                $adminArr = GetLocalAdminGroupMember -Platform "W10"
            }
            "^Microsoft Windows 7.*" {
                if ($PSVersionTable.PSVersion.Major -ne 5) {
                    Throw [System.NotImplementedException] "Unsupported OS: Windows 7 without WMF 5.1"
                }
                else {
                    $adminArr = GetLocalAdminGroupMember -Platform "W7"
                }
            }
        }
        return $adminArr
    }
}