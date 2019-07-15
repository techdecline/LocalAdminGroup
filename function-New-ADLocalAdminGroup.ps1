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
        $GroupPath
    )

    process {
        #region Variables
        $targetGroupName = $Prefix + $ComputerName
        #endregion

        #region AD Computer Search
        Write-Verbose "Searching Active Directory for Client: $ComputerName"
        $computerObj = Get-ADComputer -Identity $ComputerName
        if (-not $computerObj) {
            Write-Warning -Message "Could not find machine $ComputerName in Active Directory"
            return $null
        }
        else {
            Write-Verbose -Message "Found machine $ComputerName in Active Directory"
        }
        #endregion
        <#
        #region Online Check
        Write-Verbose -Message "Checking WSMan connectivity to $ComputerName"
        if (Test-WSMan -ComputerName $ComputerName) {
            Write-Verbose "Successfully connected to: $ComputerName"
        }
        elseif ($Force) {
            Write-Verbose "Machine is offline, but Parameter Force is set"
            $online = $false
        }
        else {
            Write-Warning -Message "Machine $ComputerName is offline and Parameter Force is not set"
            return $null
        }
        #endregion
        #>

        #region AD Group Check
        Write-Verbose -Message "Checking for existing AD group: $targetGroupName"
        try {
            $adGroup = Get-ADGroup -Identity $targetGroupName
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            $adGroup = $null
        }

        if ($adGroup) {
            Write-Verbose "Group exists: true"
            return $adGroup
        }
        else {
            Write-Verbose "Group exists: false"
            $groupParam = @{
                Name = $targetGroupName
                GroupCategory = "Security"
                GroupScope = "Global"
            }
            if ($GroupPath) {
                if ([adsi]::Exists($GroupPath)) {
                    Write-Verbose "Group will be created at: $GroupPath"
                    $groupParam.Add("Path",$GroupPath)
                }
                else {
                    throw "LDAP location does not exist"
                }
            }
            try {
                Write-Verbose "Adding Group: $targetGroupName"
                $groupObj = New-ADGroup @groupParam -ErrorAction Stop -PassThru
            }
            catch [System.Management.Automation.ActionPreferenceStopException] {
                throw "Could not create group: $targetGroupName"
            }
            return $groupObj
        }
        #endregion
    }
}