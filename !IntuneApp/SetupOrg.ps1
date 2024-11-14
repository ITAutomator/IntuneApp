# https://github.com/MSEndpointMgr/IntuneWin32App/issues/156#issuecomment-2103792262
#
$TenantID = Read-Host -Prompt "Enter the Tenant ID or FQDN"

#Interactive Login with scope to create and modify an application
Try {
  $Result = Get-MgContext -ErrorAction Stop
  If ($null -eq $Result) {
      Write-Host "Connecting to tenant for setup. Login as a Global Admin User"
      Connect-MgGraph -Scopes "Application.ReadWrite.All, Directory.Read.All" -TenantId $TenantID
  }
} catch {
  Write-Host "Error: Need to load module MS-Graph" -WarningAction Break
}

$NewApp = New-MgApplication -DisplayName "IntuneWin32App"
Write-Host "Created new application $($NewApp.DisplayName)" -ForegroundColor Green
# Required Permissions
$BodyParams = '{
  "requiredResourceAccess": [{
    "resourceAppId": "00000003-0000-0000-c000-000000000000",
    "requiredResourceAccess": [
      {
        "resourceAppId": "00000003-0000-0000-c000-000000000000",
        "resourceAccess": [
          {
            "id": "78145de6-330d-4800-a6ce-494ff2d33d07",
            "type": "Role"
          },
          {
            "id": "9241abd9-d0e6-425a-bd4f-47ba86e767a4",
            "type": "Role"
          }
        ]
      }
    ]
  }]
}'

Update-MgApplication -ApplicationId $NewApp.Id -BodyParameter $BodyParams

Write-Host "Login to Azure portal and approve application permissions"
Start-process "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$($NewApp.AppId)/isMSAApp~/false"
Write-Host "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$($NewApp.AppId)/isMSAApp~/false" -ForegroundColor White