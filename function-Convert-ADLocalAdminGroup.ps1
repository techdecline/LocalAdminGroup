<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Convert-ADLocalAdminGroup {
    [CmdletBinding()]
    param (
        # Target ComputerName
        [Parameter(Mandatory)]
        [ValidateScript({$_.Length -le 15 -and (Test-WSMan $_)})]
        [String]
        $ComputerName,

        # Target AD Group Object
        [Parameter(Mandatory)]
        [Microsoft.ActiveDirectory.Management.ADGroup]
        $GroupObject
    )

    process {
        #region Functions
        function Get-RemoteAdminGroupMember {
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
        #endregion

        #region CurrentLocalAdminGroup
        try {
            Write-Verbose "Fetching local admin group members on: $ComputerName"
            $currentAdminArr = Get-ADRemoteAdminGroupMember -ComputerName $ComputerName
        }
        catch [System.NotImplementedException] {
            Write-Warning "Unsupported OS. Will return $false"
            return $false
            #throw "Unsupported OS"
        }
        #endregion

        #region AddCurrentLocalAdminGroupMembers
        if (-not ($currentAdminArr)) {
            Write-Verbose "No members to add"
            return $true
        }
        else {
            Write-Verbose "Adding new members to ADGroup: $GroupObject"
            try {
                $currentAdminArr | ForEach-Object {
                    $currentObj = ($_ -split "\\")[1]
                    Write-Verbose "Adding member: $currentObj"
                    Add-ADGroupMember -Identity $GroupObject -Members $currentObj
                }
            }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                throw "Unable to find object in AD"
            }
        }
        #endregion

        #region ReplaceInLocalAdminGroup
        Write-Verbose "Adding AD Group $($GroupObject.Name) to local Admin Group on: $ComputerName"
        try {
            Add-ADRemoteAdminGroupMember -ComputerName $ComputerName -Member $GroupObject.Name
            $currentAdminArr | ForEach-Object {
                $currentObj = ($_ -split "\\")[1]
                Write-Verbose "Removing $currentObj from Local Admin Group on: $ComputerName"
                Remove-adRemoteAdminGroupMember -ComputerName $ComputerName -Member $currentObj | Out-Null
            }
        }
        catch {

        }
        return $true
        #endregion
    }
}