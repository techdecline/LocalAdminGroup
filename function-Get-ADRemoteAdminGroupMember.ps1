<#
    .SYNOPSIS
    .DESCRIPTION
    .EXAMPLE
#>
function Get-ADRemoteAdminGroupMember {
    [CmdletBinding()]
    param (
        [String]$ComputerName,
        [String]$GroupName
    )

    Function Get-LocalGroupMember {
        [cmdletbinding()]

        Param(
        [Parameter(Position = 0)]
        [ValidateNotNullorEmpty()]
        [string]$Name = "Administrators",

        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [Alias("CN","host")]
        [string[]]$Computername = $env:computername
        )


        Begin {
            Write-Verbose "[Starting] $($MyInvocation.Mycommand)"
            Write-Verbose "[Begin]    Querying members of the $Name group"
        } #begin

        Process {

        foreach ($computer in $computername) {

            #define a flag to indicate if there was an error
            $script:NotFound = $False

            #define a trap to handle errors because we're not using cmdlets that
            #could support Try/Catch. Traps must be in same scope.
            Trap [System.Runtime.InteropServices.COMException] {
                $errMsg = "Failed to enumerate $name on $computer. $($_.exception.message)"
                Write-Warning $errMsg

                #set a flag
                $script:NotFound = $True

                Continue
            }

            #define a Trap for all other errors
            Trap {
            Write-Warning "Oops. There was some other type of error: $($_.exception.message)"
            Continue
            }

            Write-Verbose "[Process]  Connecting to $computer"
            #the WinNT moniker is case-sensitive
            [ADSI]$group = "WinNT://$computer/$Name,group"

            Write-Verbose "[Process]  Getting group member details"
            $members = $group.invoke("Members")

            Write-Verbose "[Process]  Counting group members"

            if (-Not $script:NotFound) {
                $found = ($members | measure).count
                Write-Verbose "[Process]  Found $found members"

                if ($found -gt 0 ) {
                $members | foreach {

                    #define an ordered hashtable which will hold properties
                    #for a custom object
                    $Hash = [ordered]@{Computername = $computer.toUpper()}

                    #Get the name property
                    $hash.Add("Name",$_[0].GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null))

                    #get ADS Path of member
                    $ADSPath = $_[0].GetType().InvokeMember("ADSPath", 'GetProperty', $null, $_, $null)
                    $hash.Add("ADSPath",$ADSPath)

                    #get the member class, ie user or group
                    $hash.Add("Class",$_[0].GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null))

                    <#
                    Domain members will have an ADSPath like WinNT://MYDomain/Domain Users.
                    Local accounts will be like WinNT://MYDomain/Computername/Administrator
                    #>

                    $hash.Add("Domain",$ADSPath.Split("/")[2])

                    #if computer name is found between two /, then assume
                    #the ADSPath reflects a local object
                    if ($ADSPath -match "/$computer/") {
                        $local = $True
                        }
                    else {
                        $local = $False
                        }
                    $hash.Add("IsLocal",$local)

                    #turn the hashtable into an object
                    New-Object -TypeName PSObject -Property $hash
                } #foreach member
                }
                else {
                    Write-Warning "No members found in $Name on $Computer."
                }
            } #if no errors
        } #foreach computer

        } #process

        End {
            Write-Verbose "[Ending]  $($MyInvocation.Mycommand)"
        } #end
    } #end function
    $objArr = (Get-LocalGroupMember -Name Administrators -Computername cm-client1 | Where-Object {$_.Domain -eq $env:USERDOMAIN}).Name
    return $objArr
}