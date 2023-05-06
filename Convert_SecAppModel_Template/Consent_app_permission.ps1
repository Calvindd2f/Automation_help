# Define the required variables
$appId = "<APPLICATION_ID>"
$resourceAppId = "<RESOURCE_APP_ID>"
$resourceAppRoleId = "<RESOURCE_APP_ROLE_ID>"
$accessToken = "<ACCESS_TOKEN>"
$tenantId = "<TENANT_ID>"

# Construct the consent URL
$consentUrl = "https://login.microsoftonline.com/$tenantId/adminconsent?" +
              "client_id=$appId&" +
              "scope=https://graph.microsoft.com/Application.ReadWrite.All&" +
              "redirect_uri=http://localhost/myapp"

# Open the consent URL in a web browser
Start-Process $consentUrl

# Wait for the user to grant consent
Write-Host "Waiting for user to grant consent..." -ForegroundColor Yellow
Read-Host "Press Enter to continue"

# Use the access token to grant the application consent for the requested permissions
$permissionUrl = "https://graph.microsoft.com/v1.0/servicePrincipals/$resourceAppId/appRoleAssignments"
$permissionData = @{
    principalId = $appId
    resourceId = $resourceAppId
    appRoleId = $resourceAppRoleId
}
$headers = @{
    Authorization = "Bearer $accessToken"
    Content-Type = "application/json"
}
Invoke-RestMethod -Uri $permissionUrl -Method Post -Headers $headers -Body ($permissionData | ConvertTo-Json)
