Remove-Module LocalAdminGroup -Force
Import-Module .\LocalAdminGroup.psd1

Convert-CMRemoteAdminGroup -SecretKey 11513693-769e-4285-b6fb-fa4b2338ad02 -WebServiceUrl http://cm-server1.decline.lab/ConfigMgrWebService/ConfigMgr.asmx -LocalTargetGroupName Administrators -ExcludeIdentityArr @("cm-push","Domain Admins","Administrator")
