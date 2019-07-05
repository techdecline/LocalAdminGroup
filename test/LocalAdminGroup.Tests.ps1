$ModuleManifestName = 'LocalAdminGroup.psd1'
$ModuleName = ($ModuleManifestName -split "\.")[0]
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"


Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath | Should Not BeNullOrEmpty
        $? | Should Be $true
    }
}

Describe "Module Organisation Tests" {
    It  "Has Root Module $ModuleName.psm1" {
        "$PSScriptRoot\..\$ModuleName.psm1" | Should exist
    }

    It "$moduleName is valid PowerShell code" {
        $psFile = Get-Content -Path "$PSScriptRoot\..\$moduleName.psm1" `
                              -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
        $errors.Count | Should Be 0
    }
}

Describe  "Module Function Tests" {
    It "$ModuleName has functions" {
        "$PSScriptRoot\..\function-*.ps1" | should exist
    }

    $functionArr = ("New-ADLocalAdminGroup","Convert-ADLocalAdminGroup","Get-ADRemoteAdminGroupMember","Add-ADRemoteAdminGroupMember","Remove-ADRemoteAdminGroupMember")

    foreach ($functionStr in $functionArr ) {
        Context "Test function $functionStr" {
            It "function-$functionStr.ps1 should exist" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | should exist
            }

            It "$functionStr.ps1 should have a help block" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch '<#'
                 "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch '#>'
            }

            It "$functionStr.ps1 should have a SYNOPSIS in the help block" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch 'SYNOPSIS'
            }

            It "$functionStr.ps1 should have a DESCRIPTION in the help block" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch 'DESCRIPTION'
            }

            It "$functionStr.ps1 should have a EXAMPLE in the help block" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch 'EXAMPLE'
            }

            It "$functionStr.ps1 should be an advanced function" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch 'function'
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch 'cmdletbinding'
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should FileContentMatch 'param'
            }
              <#
              It "$functionStr.ps1 should contain Write-Verbose blocks" {
                "$PSScriptRoot\..\function-$functionStr.ps1" | Should Contain 'Write-Verbose'
            }
                #>
            It "$functionStr.ps1 is valid PowerShell code" {
                $psFile = Get-Content -Path "$PSScriptRoot\..\function-$functionStr.ps1" `
                                      -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
                $errors.Count | Should Be 0
            }
        }

        Context "$functionStr has tests" {
            It "$PSScriptRoot\function-$functionStr.Tests.ps1 should exist" {
                "$PSScriptRoot\function-$functionStr.Tests.ps1" | should exist
            }
        }
    }
}

