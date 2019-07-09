$moduleName = "LocalAdminGroup"
Remove-Module $moduleName -Force -ErrorAction SilentlyContinue

Import-Module "$PSScriptRoot\..\$moduleName.psd1"

InModuleScope LocalAdminGroup {
}