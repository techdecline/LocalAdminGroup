<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Get-CMGroupMember {
    [CmdletBinding()]
    param (
        # Secret Key
        [Parameter(Mandatory)]
        [String]
        $SecretKey,

        # Target Group Name
        [Parameter(Mandatory)]
        [String]$GroupName,

        # Web Service URL
        [Parameter(Mandatory)]
        [ValidateScript({Invoke-webrequest -Uri $_})]
        [string]
        $WebServiceUrl
    )
    process {
        # Connect to Web Service
        $URI = $WebServiceUrl
        $Web = New-WebServiceProxy -Uri $URI

        try {
            $result = $Web.GetADGroupMembers($SecretKey,$GroupName)
            if ($result) {
                return $result
            }
            else {
                return $null
            }
        }
        catch [System.Management.Automation.RuntimeException] {
            throw "Could not get resource using CM web service"
        }
    }
}