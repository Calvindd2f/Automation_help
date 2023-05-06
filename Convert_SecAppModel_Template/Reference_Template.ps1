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
