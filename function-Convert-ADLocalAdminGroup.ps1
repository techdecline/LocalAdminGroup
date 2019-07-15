<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Convert-ADLocalAdminGroup {
    [CmdletBinding()]
    param (
        # Computer Name to be converted
        [Parameter(Mandatory)]
        [String[]]
        $ComputerName,

        # AD Group Prefix
        [Parameter(Mandatory=$false)]
        [ValidateScript({$_.Length -le 5})]
        [String]
        $Prefix = "LAG_",

        # Log File Path
        [Parameter(Mandatory=$false)]
        [String]$LogFilePath = $env:TEMP,

        # Name of local Group to be converted
        [Parameter(Mandatory=$false)]
        [String]$LocalTargetGroupName = "Administrators",

        # Identities to be ignored during the conversion
        [Parameter(Mandatory=$false)]
        [String[]]$ExcludeIdentityArr = @("Administrator","cm-push","Domain Admins")
    )

    process {
        # Load Modules
        Import-Module LogStream -MinimumVersion 1.0.2
        #Import-Module C:\code\LocalAdminGroup\LocalAdminGroup.psd1
        Import-Module ActiveDirectory

        # Initialize Logging
        $LogFilePath = Join-Path -Path $LogFilePath -ChildPath "Convert-Group_$(get-date -Format yyyyMMdd).txt"
        Start-Log -LogFilePath $LogFilePath | Out-Null

        foreach ($computer in $ComputerName) {
            $groupName = $Prefix + $computer
            Write-VerboseLog -LogFilePath $LogFilePath -Message "Converting Local Admin Group for Host: $computer"
            try {
                # Get Current Admin Users
                try {
                    $adminUserArr = Get-LocalGroupMember -Name $LocalTargetGroupName -ComputerName $computer -ErrorAction Stop
                }
                catch [System.Management.Automation.ActionPreferenceStopException] {
                    Write-ErrorLog -LogFilePath $LogFilePath -Message "Could not fetch current group members on: $computer"
                    continue
                }

                if ($adminUserArr) {
                    # Add Current Admin Users to Domain Group
                    Write-VerboseLog -LogFilePath $LogFilePath -Message "Checking current group for exclusion criteria"
                    try {
                        $userStr = ($adminUserArr | Where-Object {$_.Domain -eq $env:USERDOMAIN -and $ExcludeIdentityArr -notcontains $_.Name} | Select-Object -ExpandProperty Name)
                        Write-VerboseLog -LogFilePath $LogFilePath -Message "Users to be added are: $($userStr -join ",")"
                        Add-ADGroupMember -Identity $groupName -Members $userStr
                    }
                    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        Write-ErrorLog -LogFilePath $LogFilePath -Message $Error[0].Exception.Message
                        continue
                    }

                    # Adding AD Group to local Admin Group
                    try {
                        Write-VerboseLog -LogFilePath $LogFilePath -Message "Adding $groupName to local Admin Group on Client: $computer"
                        Add-ADRemoteAdminGroupMember -ComputerName $computer -Member $groupName
                    }
                    catch [System.Management.Automation.ActionPreferenceStopException] {
                        Write-ErrorLog -LogFilePath  $LogFilePath -Message "Error adding group $groupName to local admin Group on: $computer"
                    }

                    # Remove Members from local Admin Group
                    $userStr | ForEach-Object {
                        Write-VerboseLog -LogFilePath $LogFilePath -Message "Removing $_ from Admin Group on: $computer"
                        Remove-ADRemoteAdminGroupMember -ComputerName $computer -Member $_
                    }
                }
                else {
                    Write-WarningLog -LogFilePath $LogFilePath -Message "Did not receive any members on $computer"
                }




            }
            catch [System.Management.Automation.RuntimeException] {
                Write-ErrorLog -LogFilePath $LogFilePath -Message $Error[0].Exception.Message
            }
        }

        Stop-Log -LogFilePath $LogFilePath | Out-Null
    }
}