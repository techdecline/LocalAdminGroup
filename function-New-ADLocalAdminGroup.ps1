<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function New-ADLocalAdminGroup {
    [CmdletBinding()]
    param (
        # Target ComputerName
        [Parameter(Mandatory)]
        [ValidateScript({$_.Length -le 15})]
        [String]
        $ComputerName,

        # AD Group Prefix
        [Parameter(Mandatory=$false)]
        [ValidateScript({$_.Length -le 5})]
        [String]
        $Prefix = "LAG_",

        # LDAP Path for Group Creation
        [Parameter(Mandatory=$false)]
        [ValidatePattern("^LDAP://.*")]
        [string]
        $GroupPath,

        # Log File Path
        [Parameter(Mandatory=$false)]
        [String]
        $LogFilePath = $env:TEMP
    )

    process {
        # Initialize Logging
        $LogFilePath = Join-Path -Path $LogFilePath -ChildPath "New-ADLocalAdminGroup_$(get-date -Format yyyyMMdd).txt"
        Start-Log -LogFilePath $LogFilePath | Out-Null

        #region Variables
        $targetGroupName = $Prefix + $ComputerName
        #endregion

        #region AD Computer Search
        Write-VerboseLog -LogFilePath $LogFilePath -Message  "Searching Active Directory for Client: $ComputerName"
        $computerObj = Get-ADComputer -Identity $ComputerName
        if (-not $computerObj) {
            Write-WarningLog -LogFilePath $LogFilePath -Message  -Message "Could not find machine $ComputerName in Active Directory"
            Stop-Log -LogFilePath $LogFilePath | Out-Null
            return $null
        }
        else {
            Write-VerboseLog -LogFilePath $LogFilePath -Message  -Message "Found machine $ComputerName in Active Directory"
        }
        #endregion
        <#
        #region Online Check
        Write-VerboseLog -LogFilePath $LogFilePath -Message  -Message "Checking WSMan connectivity to $ComputerName"
        if (Test-WSMan -ComputerName $ComputerName) {
            Write-VerboseLog -LogFilePath $LogFilePath -Message  "Successfully connected to: $ComputerName"
        }
        elseif ($Force) {
            Write-VerboseLog -LogFilePath $LogFilePath -Message  "Machine is offline, but Parameter Force is set"
            $online = $false
        }
        else {
            Write-WarningLog -LogFilePath $LogFilePath -Message  -Message "Machine $ComputerName is offline and Parameter Force is not set"
            return $null
        }
        #endregion
        #>

        #region AD Group Check
        Write-VerboseLog -LogFilePath $LogFilePath -Message  -Message "Checking for existing AD group: $targetGroupName"
        try {
            $adGroup = Get-ADGroup -Identity $targetGroupName
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            $adGroup = $null
        }

        if ($adGroup) {
            Write-VerboseLog -LogFilePath $LogFilePath -Message  "Group exists: true"
            Stop-Log -LogFilePath $LogFilePath | Out-Null
            return $adGroup
        }
        else {
            Write-VerboseLog -LogFilePath $LogFilePath -Message  "Group exists: false"
            $groupParam = @{
                Name = $targetGroupName
                GroupCategory = "Security"
                GroupScope = "Global"
            }
            if ($GroupPath) {
                if ([adsi]::Exists($GroupPath)) {
                    Write-VerboseLog -LogFilePath $LogFilePath -Message  "Group will be created at: $GroupPath"
                    $groupParam.Add("Path",$GroupPath)
                }
                else {
                    Write-ErrorLog -LogFilePath $LogFilePath -Message  "LDAP location does not exist"
                    Stop-Log -LogFilePath $LogFilePath | Out-Null
                    return $null
                }
            }
            try {
                Write-VerboseLog -LogFilePath $LogFilePath -Message  "Adding Group: $targetGroupName"
                $groupObj = New-ADGroup @groupParam -ErrorAction Stop -PassThru
            }
            catch [System.Management.Automation.ActionPreferenceStopException] {
                Write-ErrorLog -LogFilePath $LogFilePath -Message  "Could not create group: $targetGroupName"
                Stop-Log -LogFilePath $LogFilePath | Out-Null
                return $null
            }
            Stop-Log -LogFilePath $LogFilePath | Out-Null
            return $groupObj
        }
        #endregion
    }
}