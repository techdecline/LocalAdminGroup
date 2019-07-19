<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Add-CMRemoteAdminGroup {
    [CmdletBinding(DefaultParameterSetName="AddUser")]
    param (
        # Secret Key
        [Parameter(Mandatory)]
        [String]
        $SecretKey,

        # Target Group Name
        [Parameter(Mandatory)]
        [String]$TargetGroupName,

        # Web Service URL
        [Parameter(Mandatory)]
        [ValidateScript({Invoke-webrequest -Uri $_})]
        [string]
        $WebServiceUrl,

        # Member User
        [Parameter(Mandatory,ParameterSetName="AddUser")]
        [String]
        $MemberUser,

        # Member group
        [Parameter(Mandatory,ParameterSetName="AddGroup")]
        [String]
        $MemberGroup,

        # Member Computer
        [Parameter(Mandatory,ParameterSetName="AddComputer")]
        [String]
        $MemberComputer
    )
    process {
        # Connect to Web Service
        $URI = $WebServiceUrl
        $Web = New-WebServiceProxy -Uri $URI

        # Invoke method
        switch ($PSCmdlet.ParameterSetName) {
            "AddUser" {
                try {
                    $result = $Web.AddADUserToGroup($SecretKey,$TargetGroupName,$MemberUser)
                    if ($result) {
                        return $true
                    }
                    else {
                        return $false
                    }
                }
                catch [System.Management.Automation.RuntimeException] {
                    throw "Could not add resource using CM web service"
                }
            }
            "AddComputer" {
                try {
                    $result = $Web.AddADComputerToGroup($SecretKey,$TargetGroupName,$MemberComputer)
                    if ($result) {
                        return $true
                    }
                    else {
                        return $false
                    }
                }
                catch [System.Management.Automation.RuntimeException] {
                    throw "Could not add resource using CM web service"
                }
            }
            "AddGroup" {
                Get-CMGroupMember -SecretKey $SecretKey -GroupName $MemberGroup -WebServiceUrl $WebServiceUrl | ForEach-Object {
                    $ldapPath = "LDAP://" + $_
                    switch (([adsi]$ldapPath).SchemaClassName) {
                        "user" { Add-CMRemoteAdminGroup -SecretKey $SecretKey -TargetGroupName $TargetGroupName -WebServiceUrl $WebServiceUrl -MemberUser ([adsi]$ldapPath).sAMAccountName }
                        "group" { Add-CMRemoteAdminGroup -SecretKey $SecretKey -TargetGroupName $TargetGroupName -WebServiceUrl $WebServiceUrl -MemberGroup ([adsi]$ldapPath).sAMAccountName  }
                        "computer" { Add-CMRemoteAdminGroup -SecretKey $SecretKey -TargetGroupName $TargetGroupName -WebServiceUrl $WebServiceUrl -MemberComputer ([adsi]$ldapPath).sAMAccountName  }
                    }
                }
            }
            Default {
                Throw [System.NotImplementedException] "Unsupported feature: $($PSCmdlet.ParameterSetName)"
            }
        }
    }
}