<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Add-ADRemoteAdminGroupMember {
    [CmdletBinding()]
    param (
        [String]$ComputerName,
        [String]$Member
    )
    invoke-command -ComputerName $ComputerName -ArgumentList $Member -ScriptBlock {
        Param ([String]$Member)
        $osVersion = (Get-WmiObject -Class win32_operatingsystem -Property Caption).Caption
        switch -regex ($osVersion) {
            "^Microsoft Windows 10.*" {
                Add-LocalGroupMember -SID S-1-5-32-544 -Member $Member
            }
            "^Microsoft Windows 7.*" {
                if ($PSVersionTable.PSVersion.Major -ne 5) {
                    Throw [System.NotImplementedException] "Unsupported OS: Windows 7 without WMF 5.1"
                }
                else {
                    Add-LocalGroupMember -SID S-1-5-32-544 -Member $Member
                }
            }
        }
        return $true
    }
}