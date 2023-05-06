# Convert_SecAppModel_Template
Python script that detects MS365 logon modules and generates a template for the Microsoft Secure Application Model  
  
> Usage  
  
```python
python csamt.py path/to/target_script.ps1
```

> Script to detect
  
```python
import argparse
import re

# Define the command-line arguments
parser = argparse.ArgumentParser(description="Generate a Microsoft Secure Application Model template for a PowerShell script.")
parser.add_argument("script", metavar="SCRIPT", type=str, help="the path to the target PowerShell script")
args = parser.parse_args()

# The modules to search for
modules = ["ExchangeOnline", "MSOnline", "AzureAD", "MgGraph"]

# Initialize the template variables
template = {
    "UserToOffboard": "jdoe",
    "CustomerDefaultDomainname": "example.com",
    "Secrets": []
}

# Parse the PowerShell script and extract the required secrets
with open(args.script) as f:
    script_contents = f.read()
for module in modules:
    # Search for non-secure module usage in the script
    match = re.search(rf"({module})\s*[-\/]?\w+\s*[-\/]?\w+", script_contents)
    if match:
        # Extract the secret name and add it to the template
        secret_name = f"O365{module.capitalize()}Secret"
        template["Secrets"].append(secret_name)

# Print the generated template
print(template)
```

------------------------------------------------------------------------------------------------------------------------------------------------


## A reference template:  
This specific example is for a employee termination scipt - however the process of connecting securely can still be used as a template


```Powershell
# Define the user info and secrets
$userToOffboard = "jdoe"
$CustomerDefaultDomainname = "example.com"
$secrets = @{
    "ApplicationId" = "<YOUR_APPLICATION_ID>"
    "ApplicationSecret" = ConvertTo-SecureString "<YOUR_APPLICATION_SECRET>" -AsPlainText -Force
    "RefreshToken" = "<YOUR_REFRESH_TOKEN>"
    "ExchangeRefreshToken" = "<YOUR_EXCHANGE_REFRESH_TOKEN>"
    "UPN" = "<YOUR_UPN>"
    "Skiplist" = "Skiplist item 1,Skiplist item 2"
}

# Convert the secrets to secure strings
$secrets = $secrets | ForEach-Object {
    $_.Value = ConvertTo-SecureString $_.Value -AsPlainText -Force
    $_
}

# Get the Microsoft Graph and Azure AD tokens
Write-Host "Getting Microsoft Graph and Azure AD tokens..." -ForegroundColor Green
$graphToken = New-PartnerAccessToken -ApplicationId $secrets.ApplicationId -Credential (New-Object System.Management.Automation.PSCredential($secrets.ApplicationId, $secrets.ApplicationSecret)) -RefreshToken $secrets.RefreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Tenant $CustomerDefaultDomainname
$aadGraphToken = New-PartnerAccessToken -ApplicationId $secrets.ApplicationId -Credential (New-Object System.Management.Automation.PSCredential($secrets.ApplicationId, $secrets.ApplicationSecret)) -RefreshToken $secrets.RefreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal -Tenant $CustomerDefaultDomainname

# Get the Exchange Online token
Write-Host "Getting Exchange Online token..." -ForegroundColor Green
$exchangeToken = New-PartnerAccessToken -ApplicationId "a0c73c16-a7e3-4564-9a95-2bdf47383716" -RefreshToken $secrets.ExchangeRefreshToken -Scopes 'https://outlook.office365.com/.default' -Tenant $CustomerDefaultDomainname
$exchangeTokenValue = ConvertTo-SecureString "Bearer $($exchangeToken.AccessToken)" -AsPlainText -Force

# Connect to Azure AD and Microsoft Graph
Write-Host "Connecting to Azure AD and Microsoft Graph..." -ForegroundColor Green
Connect-AzureAD -AadAccessToken $aadGraphToken.AccessToken -AccountId $secrets.UPN -MsAccessToken $graphToken.AccessToken -TenantId $CustomerDefaultDomainname

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Green
$credential = New-Object System.Management.Automation.PSCredential($secrets.UPN, $exchangeTokenValue)
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell-liveid?DelegatedOrg=$($CustomerDefaultDomainname)&BasicAuthToOAuthConversion=true" -Credential $credential -Authentication Basic -AllowRedirection
Import-PSSession $session -AllowClobber

# Use the Microsoft PowerShell modules securely
# ...

# Disconnect from the Exchange Online session
Remove-PSSession $session
```  
  
------------------------------------------------------------------------------------------------------------------------------------------------  
  
## Creating an Application in Azure AD (purpose and scope of script)(Powershell):  

```powershell
# Define the required variables
$appName = "MyApp"
$appUri = "http://localhost/myapp"
$replyUrls = @("http://localhost/myapp")
$password = "<PASSWORD>"

# Install the Azure AD PowerShell module if necessary
if (-not (Get-Module AzureAD -ErrorAction SilentlyContinue)) {
    Install-Module AzureAD -Force
}

# Connect to Azure AD using an admin account
Connect-AzureAD

# Create the Azure AD application
$app = New-AzureADApplication -DisplayName $appName -IdentifierUris $appUri -ReplyUrls $replyUrls

# Generate a password for the application
$passwordCredential = New-Object Microsoft.Open.AzureAD.Model.PasswordCredential
$passwordCredential.EndDate = [System.DateTime]::UtcNow.AddYears(1)
$passwordCredential.SecretText = $password
$app.PasswordCredentials = @($passwordCredential)

# Print the application ID and password
$app | Select-Object -Property AppId
$passwordCredential | Select-Object -Property SecretText
```

## Creating an Application in Azure AD (purpose and scope of script)(Python):  

> The following need their appropriate values changed.  

+ PASSWORD  
+ TENANT_ID  
+ CLIENT_ID  
+ CLIENT_SECRET  
+ RESOURCE_APP_ID  
+ RESOURCE_APP_ROLE_ID  

```python
import requests
import json

# Define the required variables
app_name = "MyApp"
app_uri = "http://localhost/myapp"
reply_urls = ["http://localhost/myapp"]
password = "<PASSWORD>"
tenant_id = "<TENANT_ID>"
client_id = "<CLIENT_ID>"
client_secret = "<CLIENT_SECRET>"

# Define the Microsoft Graph API endpoints
app_endpoint = f"https://graph.microsoft.com/v1.0/applications"
permission_endpoint = f"https://graph.microsoft.com/v1.0/servicePrincipals/{client_id}/appRoleAssignments"

# Define the HTTP headers and request data
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}
app_data = {
    "displayName": app_name,
    "identifierUris": [app_uri],
    "replyUrls": reply_urls,
    "passwordCredentials": [{
        "startDate": "2021-01-01T00:00:00Z",
        "endDate": "2022-01-01T00:00:00Z",
        "secretText": password
    }]
}
permission_data = {
    "principalId": client_id,
    "resourceId": "<RESOURCE_APP_ID>",
    "appRoleId": "<RESOURCE_APP_ROLE_ID>"
}

# Create the Azure AD application
response = requests.post(app_endpoint, headers=headers, data=json.dumps(app_data))
app_id = response.json()["id"]

# Grant the required permissions to the application
response = requests.post(permission_endpoint, headers=headers, data=json.dumps(permission_data))

# Print the application ID
print(f"Application ID: {app_id}")
```
 
You'll need to obtain an access token for the Microsoft Graph API using your Azure AD admin account, and you'll need to grant the application permission to the appropriate Azure AD resources.  
  
------------------------------------------------------------------------------------------------------------------------------------------------

## Grant an Azure AD application consent for the requested permissions(powershell):  

```powershell
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
```

## Grant an Azure AD application consent for the requested permissions(Python):  


```python
import requests

# Define the required variables
app_id = "<APPLICATION_ID>"
resource_app_id = "<RESOURCE_APP_ID>"
resource_app_role_id = "<RESOURCE_APP_ROLE_ID>"
access_token = "<ACCESS_TOKEN>"

# Define the consent URL and consent data
consent_url = "https://login.microsoftonline.com/common/adminconsent"
consent_data = {
    "client_id": app_id,
    "redirect_uri": "http://localhost/myapp",
    "scope": f"https://graph.microsoft.com/{resource_app_id}/{resource_app_role_id}",
}

# Open the consent URL in a web browser
import webbrowser
webbrowser.open(consent_url + "?" + "&".join(f"{k}={v}" for k, v in consent_data.items()))

# Wait for the user to grant consent
input("Press Enter to continue...")

# Use the access token to grant the application consent for the requested permissions
permission_url = f"https://graph.microsoft.com/v1.0/servicePrincipals/{resource_app_id}/appRoleAssignments"
permission_data = {
    "principalId": app_id,
    "resourceId": resource_app_id,
    "appRoleId": resource_app_role_id,
}
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json",
}
response = requests.post(permission_url, headers=headers, json=permission_data)
response.raise_for_status()
```
