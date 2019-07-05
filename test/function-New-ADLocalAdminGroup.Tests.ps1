$moduleName = "LocalAdminGroup"
Remove-Module $moduleName -Force -ErrorAction SilentlyContinue

Import-Module "$PSScriptRoot\..\$moduleName.psd1"

# Mock functions
function TestGroup([String]$Name) {
    $group = 1 | Select-Object -Property @{Name = "Name";Expression = {$Name}}
    return $group
}

function TestComputer([String]$Name) {
    $computer = 1 | Select-Object -Property @{Name = "Name";Expression = {$Name}}
    return $computer
}

InModuleScope LocalAdminGroup {
    Describe "New-ADLocalAdminGroup Parameter Validation" {
        It "Should prevent long Host Names" {
            {New-ADLocalAdminGroup -ComputerName VeryVeryLongComputerName }| Should Throw
        }

        It "Should prevent long prefixes" {
            { New-ADLocalAdminGroup -ComputerName ComputerName -Prefix "MoreThanFive" } | Should Throw
        }

        It "Should have Parameter ComputerName" {
            Get-Command New-ADLocalAdminGroup | Should HaveParameter ComputerName
        }

        It "Should have Parameter Prefix" {
            Get-Command New-ADLocalAdminGroup | Should HaveParameter Prefix
        }

        It "Should have Parameter GroupPath" {
            Get-Command New-ADLocalAdminGroup | Should HaveParameter GroupPath
        }

        It "Should prevent irregular Group Path format" {
            {New-ADLocalAdminGroup -ComputerName ComputerName -GroupPath "wrongFormat"} | Should Throw
        }
    }

    Describe "New-ADLocalAdminGroup Logic Validation" {
        # Mock definitions
        Mock -CommandName Get-ADComputer -ParameterFilter {"NotExisting" -eq $Identity} -MockWith {}
        <#
        Mock -CommandName Get-ADComputer -ParameterFilter {"NotOnline" -eq $Identity} -MockWith {
            TestComputer -Name "NotOnline"
        } #>
        Mock -CommandName Get-ADComputer -ParameterFilter {"GroupExists" -eq $Identity} -MockWith {
            TestComputer -Name "GroupExists"
        }
        Mock -CommandName Get-ADComputer -ParameterFilter {"GroupNotExists" -eq $Identity} -MockWith {
            TestComputer -Name "GroupNotExists"
        }
        #Mock -CommandName Test-WSMan -ParameterFilter {$ComputerName -eq "NotOnline"} -MockWith {}
        Mock -CommandName Get-ADGroup -MockWith {}
        Mock -CommandName Get-ADGroup -ParameterFilter {"LAG_GroupExists" -eq $Identity} -MockWith {
            TestGroup -Name "LAG_GroupExists"
        }
        Mock -CommandName New-ADGroup -ParameterFilter {$Name -eq "LAG_GroupNotExists"} -MockWith {
            TestGroup -Name "LAG_GroupNotExists"
        }

        It "Should return null value if computer object does not exist" {
            New-ADLocalAdminGroup -ComputerName "NotExisting" | Should Be $null
            Assert-MockCalled -CommandName Get-ADComputer -Scope It -Times 1
        }
        <#
        It "Should continue if machine is offline and force parameter is set" {
            New-ADLocalAdminGroup -ComputerName "NotOnline" -Force | Should not Be $null
            Assert-MockCalled -CommandName Test-WSMan -Scope It -Times 1
            Assert-MockCalled -CommandName Get-ADComputer -Scope It -Times 1
        }

        It "Should return null value if machine is offline and force parameter is not set" {
            New-ADLocalAdminGroup -ComputerName "NotOnline" | Should Be $null
            Assert-MockCalled -CommandName Test-WSMan -Scope It -Times 1
            Assert-MockCalled -CommandName Get-ADComputer -Scope It -Times 1
        }
        #>
        It "Should not re-create existing groups" {
            (New-ADLocalAdminGroup -ComputerName "GroupExists").Name | Should Be "LAG_GroupExists"
            Assert-MockCalled -CommandName Get-ADComputer -Scope It -Times 1
            Assert-MockCalled -CommandName Get-ADGroup -Times 1 -Scope 1
            Assert-MockCalled -CommandName New-ADGroup -Scope It -Times 0
        }

        It "Should create group if not existing" {
            (New-ADLocalAdminGroup -ComputerName "GroupNotExists").Name | Should Be "LAG_GroupNotExists"
            Assert-MockCalled -CommandName Get-ADComputer -Scope It -Times 1
            Assert-MockCalled -CommandName Get-ADGroup -Times 1 -Scope 1
            Assert-MockCalled -CommandName New-ADGroup -Scope It -Times 1
        }

        It "Should stop if LDAP Group Path does not exist" {
            {New-ADLocalAdminGroup -ComputerName "GroupNotExists" -GroupPath "LDAP://NoSuchOU"} | should Throw
        }
    }
}