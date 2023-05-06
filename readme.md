The two directories are more psudocode mixed with real code as a readme.   
below is `Application.ps1` contents.  

```powershell
<#  ┌────────────────────────────────────────────────────────┐
    │ Calvindd2fs SIMPLIFIED Az APPLICATION                  │
    │ VERSION 2.1 - Released May 5, 2023                     │
    │ LICENSE RESTRICTIONS APPLY -                           │
    └────────────────────────────────────────────────────────┘  #>

# The permission User.ReadWrite.All is optional in the list of permissions defined in the variable $permissionList. 
# User.ReadWrite.All may be removed, but all will not be able to update Office 365 details from within app (self service)

$domain = 'calvindd2f.ie'
$database = 'cpaq-it'
$permissionList = 'SecurityEvents.Read.All Directory.Read.All Domain.Read.All Reports.Read.All User.Read.All User.ReadWrite.All Calendars.Read AuditLog.Read.All ServiceMessage.Read.All ServiceHealth.Read.All'
$applicationName = 'Potentially a Partner Application, definitely a Application'
$homePage = 'https://' + $domain
$appIdURL = 'https://' + $domain + "/$((New-Guid).ToString())"
$logoutURL = 'https://portal.office.com'

# registering service principals , add resource permissions for appkeys , checking for modules.

Function Confirm-MicrosoftGraphServicePrincipal 
{
  $graphsp = Get-AzureADServicePrincipal -SearchString 'Microsoft Graph'
  if (!$graphsp) 
  {
    $graphsp = Get-AzureADServicePrincipal -SearchString 'Microsoft.Azure.AgregatorService'
  }
  if (!$graphsp) 
  {
    Login-AzureRmAccount -Credential $Credential
    New-AzureRmADServicePrincipal -ApplicationId '00000003-0000-0000-c000-000000000000'
    $graphsp = Get-AzureADServicePrincipal -SearchString 'Microsoft Graph'
  }
  return $graphsp
}
  
Function Confirm-MicrosoftManagementServicePrincial 
{
  $reqSP = Get-AzureADServicePrincipal -SearchString 'Office 365 Management APIs'
  if (!$reqSP) 
  {
    $reqSP = Get-AzureADServicePrincipal -SearchString 'OfficeManagePlatform'
  }
  if (!$reqSP) 
  {
    Login-AzureRmAccount -TenantId $customer.customercontextid -Credential $credentials
    New-AzureRmADServicePrincipal -ApplicationId '5393580-f805-4401-95e8-94b7a6ef2fc2'
    $reqSP = Get-AzureADServicePrincipal -SearchString 'Office 365 Management APIs'
  }
  return $reqSP
}
  
Function New-AppKey ($fromDate, $durationInYears, $pw) 
{
  $endDate = $fromDate.AddYears($durationInYears) 
  $keyId = (New-Guid).ToString()
  $key = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential -ArgumentList ($null, $endDate, $keyId, $fromDate, $pw)
  return $key
}
  
Function Initialize-AppKey 
{
  $aesManaged = New-Object -TypeName 'System.Security.Cryptography.AesManaged'
  $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
  $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
  $aesManaged.BlockSize = 128
  $aesManaged.KeySize = 256
  $aesManaged.GenerateKey()
  return [System.Convert]::ToBase64String($aesManaged.Key)
}
  
Function Test-AppKey($fromDate, $durationInYears, $pw) 
{
  $testKey = New-AppKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw
  while ($testKey.Value -match '\+' -or $testKey.Value -match '/') 
  {
    $pw = Initialize-AppKey
    $testKey = New-AppKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw
  }
  $key = $testKey
  return $key
}
  
Function Get-RequiredPermissions($requiredDelegatedPermissions, $requiredApplicationPermissions, $reqSP) 
{
  $sp = $reqSP
  $appid = $sp.AppId
  $requiredAccess = New-Object -TypeName Microsoft.Open.AzureAD.Model.RequiredResourceAccess
  $requiredAccess.ResourceAppId = $appid
  $requiredAccess.ResourceAccess = New-Object -TypeName System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
  if ($requiredDelegatedPermissions) 
  {
    Add-ResourcePermission $requiredAccess -exposedPermissions $sp.Oauth2Permissions -requiredAccesses $requiredDelegatedPermissions -permissionType 'Scope'
  } 
  if ($requiredApplicationPermissions) 
  {
    Add-ResourcePermission $requiredAccess -exposedPermissions $sp.AppRoles -requiredAccesses $requiredApplicationPermissions -permissionType 'Role'
  }
  return $requiredAccess
}
  
Function Add-ResourcePermission($requiredAccess, $exposedPermissions, $requiredAccesses, $permissionType) 
{
  foreach ($permission in $requiredAccesses.Trim().Split(' ')) 
  {
    $reqPermission = $null
    $reqPermission = $exposedPermissions | Where-Object -FilterScript {
      $_.Value -contains $permission
    }
    $resourceAccess = New-Object -TypeName Microsoft.Open.AzureAD.Model.ResourceAccess
    $resourceAccess.Type = $permissionType
    $resourceAccess.Id = $reqPermission.Id    
    $requiredAccess.ResourceAccess.Add($resourceAccess)
  }
}
  
Function Write-Error($message) 
{
  Write-Host -Object ''
  Write-Host -Object '*************************************************************************************' -ForegroundColor Red
  Write-Host -Object ''
  Write-Host -Object $message -ForegroundColor Red
  Write-Host -Object ''
  Write-Host -Object '*************************************************************************************' -ForegroundColor Red
}

Function Write-Update($message) 
{
  Write-Host -Object $message -ForegroundColor Green
}

Function Verify-Modules 
{
  try 
  {
    Write-Host -Object 'Verifying MSOnline Module' -ForegroundColor Green
    if (Get-Module -ListAvailable -Name MSOnline) 
    {

    } 
    else 
    {
      Install-Module -Name MSOnline
    }
    Write-Host -Object 'Verifying AzureAD Module' -ForegroundColor Green
    if (Get-Module -ListAvailable -Name AzureAD) 
    {

    } 
    else 
    {
      Install-Module -Name AzureAD
    }
    return $True
  }
  catch 
  {
    return $False
  }
}


 
Write-Host -Object '┌────────────────────────────────────────────────────────┐'
Write-Host -Object '│ Calvindd2fs               Az applcation                │'
Write-Host -Object '│ VERSION 2.1 - Released May 5, 2023                     │'
Write-Host -Object '│ LICENSE RESTRICTIONS -                                 │'
Write-Host -Object '└────────────────────────────────────────────────────────┘'
Write-Host -Object ''
Write-Host -Object 'Instructions' -ForegroundColor Green
Write-Host -Object 'This script will install the cpaq.it application in your partner tenant.'
Write-Host -Object 'After it completes, you will be given the values to complete your teamserver setup.'
Write-Host -Object 'If you rerun this application in the future, you will need to update your teamserver settings.'
Write-Host -Object 'More information at https://cpaq.it/Canary.txt'
Write-Host -Object ''
$prompt = ''
$prompt = Read-Host -Prompt "Specify domain or press Enter for default ($domain)"
if ($prompt -ne '') 
{
  $domain = $prompt
  $homePage = 'https://' + $domain
  $appIdURL = 'https://' + $domain + "/$((New-Guid).ToString())"
}

Write-Host -Object ''
$success = Verify-Modules

if ($success -eq $True) 
{
  Import-Module -Name MSOnline
  Write-Host -Object ''
  Write-Host -Object 'You will now be prompted for your log in. Log in as a Global Administrator for the following domain: '
  Write-Host -Object ''
  Write-Host -Object $domain -ForegroundColor Green
  Write-Host -Object ''
  Connect-AzureAD 
  $adminAgentsGroup = Get-AzureADGroup -Filter "displayName eq 'Adminagents'"
  if ($null -eq $adminAgentsGroup) 
  {
    Write-Error -Message 'This account is not setup as a Microsoft Partner' 
    $success = $True
  }
}
else 
{
  Write-Error -Message 'Rerun this script as an administrator to install the required modules.'
  # `exit` 
  # > above was removed for interoperability but also modularity.
}

if ($success -eq $True) 
{
  Write-Update 'Checking for Microsoft Graph Service Principal'  
  $graphsp = Confirm-MicrosoftGraphServicePrincipal
  $graphsp = $graphsp[0]
  $reqSP = Confirm-MicrosoftManagementServicePrincial
        
  Write-Update 'Checking for Existing Application'  
  $existingapp = $null
  $existingapp = Get-AzureADApplication -SearchString $applicationName
  if ($existingapp) 
  {
    Write-Update 'Removing Existing Application'  
    Remove-Azureadapplication -ObjectId $existingapp.objectId
    $existingapp = $null
  }
    
  Write-Update 'Installing Application'  
    
  $rsps = @()
  if ($reqSP -and $graphsp -and ($null -eq $existingapp)) 
  {
    $rsps += $graphsp
    $tenantInfo = Get-AzureADTenantDetail
    $tenant_id = $tenantInfo.ObjectId
    $initialDomain = ($tenantInfo.verifiedDomains | Where-Object -FilterScript {
        $_.Initial
    }).name
        
    $requiredResourcesAccess = New-Object -TypeName System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]
    $microsoftGraphRequiredPermissions = Get-RequiredPermissions -reqsp $graphsp -requiredApplicationPermissions $permissionList -requiredDelegatedPermissions $DelegatedPermissions
    $requiredResourcesAccess.Add($microsoftGraphRequiredPermissions)
        
    $pw = Initialize-AppKey
    $fromDate = [System.DateTime]::Now
    $appKey = Test-AppKey -fromDate $fromDate -durationInYears 99 -pw $pw
        
    Write-Update "Creating the application: $applicationName" 
    $aadApplication = New-AzureADApplication -DisplayName $applicationName `
    -HomePage $homePage `
    -ReplyUrls $homePage `
    -IdentifierUris $appIdURL `
    -LogoutUrl $logoutURL `
    -RequiredResourceAccess $requiredResourcesAccess `
    -PasswordCredentials $appKey `
    -AvailableToOtherTenants $True
                
    $servicePrincipal = New-AzureADServicePrincipal -AppId $aadApplication.AppId
            
    Write-Update 'Assigning Permissions' 
            
    foreach ($app in $requiredResourcesAccess) 
    {
      $reqAppSP = $rsps | Where-Object -FilterScript {
        $_.appid -contains $app.ResourceAppId
      }
      Write-Update "Assigning permissions for $($reqAppSP.displayName)"
      foreach ($resource in $app.ResourceAccess) 
      {
        if ($resource.Type -match 'Role') 
        {
          $success = 0
          try 
          {
            New-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId `
            -PrincipalId $servicePrincipal.ObjectId -ResourceId $reqAppSP.ObjectId -Id $resource.Id
            $success = 1
          }
          catch 
          {
 
          }
          if ($success -eq 0) 
          {
            try 
            {
              New-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId `
              -PrincipalId $servicePrincipal.ObjectId -ResourceId $reqSP.ObjectId -Id $resource.Id
            }
            catch 
            {

            }
          }
        }
      }
    }

    Add-AzureADGroupMember -ObjectId $adminAgentsGroup.ObjectId -RefObjectId $servicePrincipal.ObjectId
    Write-Update 'Application Created'
    Write-Host -Object ''
    Write-Host -Object ''
    Write-Host -Object 'Copy these values to Bitwarden or equivilant... maybe not lastpass lol.'
    Write-Host -Object ''
    Write-Host -Object ''
    Write-Host -Object 'AppId:'
    Write-Host -Object $aadApplication.AppId -ForegroundColor Green
    Write-Host -Object ''
    Write-Host -Object 'AppSecret:'
    Write-Host -Object $appKey.Value -ForegroundColor Green
    Write-Host -Object ''
    Write-Host -Object 'TenantId:'
    Write-Host -Object $tenant_id -ForegroundColor Green
    Write-Host -Object ''
    Write-Host -Object 'Realm:'
    Write-Host -Object $initialDomain -ForegroundColor Green
    Write-Host -Object ''
    Write-Host -Object ''
    Write-Update 'Application configuration detailed.'
        
    Get-PSSession | Remove-PSSession
  }
}
```
