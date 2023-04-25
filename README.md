`Starting with Sample - ability to create / delete / modify users in Exchange Online , AzAD , Graph /// MS365. ` 


# 1. PERMISSIONS

## Delegated user permissions:  


1. `Azure AD Graph API permissions:` 

    **User.ReadWrite** : Allows the user or application to create, update, and delete users.  
    **Directory.AccessAsUser.All**: Allows the user or application to perform actions on behalf of any user in the organization.  

2. `Microsoft Graph API permissions:`  

    **User.ReadWrite**: Allows the user or application to create, update, and delete users.  
    **Directory.AccessAsUser.All**: Allows the user or application to perform actions on behalf of any user in the organization.  
    **MailboxSettings.ReadWrite**: Allows the user or application to update mailbox settings, such as converting a user mailbox to a shared mailbox.  
    **LicenseManagement.ReadWrite.All**: Allows the user or application to grant or revoke licenses for all users in the organization.  

3. `Exchange Online PowerShell permissions:`   

    **Recipient Management**: Allows the user or application to create, update, and delete Exchange Online recipients, such as users and shared mailboxes.  
    **Organization Management**: Allows the user or application to perform any management tasks in Exchange Online, including converting a user mailbox to a shared mailbox.  


## Delegated application permissions:
  
1. `Azure AD Graph API permissions:`  

    **User.ReadWrite.All**: Allows the application to create, update, and delete users.  
    **Directory.ReadWrite.All**: Allows the application to perform any directory-related actions, including creating, modifying, and deleting users.  
  
2. `Microsoft Graph API permissions:`  

    **User.ReadWrite.All**: Allows the application to create, update, and delete users.  
    **Directory.ReadWrite.All**: Allows the application to perform any directory-related actions, including creating, modifying, and deleting users.  
    **MailboxSettings.ReadWrite**: Allows the application to update mailbox settings, such as converting a user mailbox to a shared mailbox.  
    **LicenseManagement.ReadWrite.All**: Allows the application to grant or revoke licenses for all users in the organization.  


# 2. CHOOSE A TOKEN FLOW:  
  
`Authorization Code Flow:` This flow is used when an application needs to access resources on behalf of a user. The user is prompted to sign in to Azure AD and consent to the application's requested permissions. Once the user grants consent, the application receives an authorization code that can be exchanged for an access token and a refresh token.  
  
`Implicit Flow:` This flow is similar to the Authorization Code Flow, but is used when the application is a client-side application, such as a Single-Page Application (SPA). In this flow, the user is redirected to Azure AD to sign in and consent to the application's requested permissions. The access token is then returned directly to the application.  
  
`Client Credentials Flow:` This flow is used when an application needs to access resources on behalf of itself, rather than a user. The application is authenticated using its own client ID and secret, and receives an access token and refresh token.  
  
`On-Behalf-Of Flow:` This flow is used when a middle-tier application needs to access resources on behalf of a user, using an access token obtained by the client application. This flow is useful when the client application has already obtained a user's access token, and the middle-tier application needs to act on behalf of the user without requiring the user to authenticate again.  
  
`Device Code Flow:` This flow is used when an application needs to authenticate a user on a device that does not have a web browser, such as a smart TV or gaming console. The user is prompted to enter a device code on a separate device with a web browser, and then signs in and consents to the application's requested permissions. The access token is then returned to the original device.  
  
# 3. TOKEN RENEWAL / LONGEVITY  
  
In this document , I will use my preferred way to automate the refresh token without just creating an inital token that does not expire / expires in a very long time.       
  
  
`Azure Key Vault` will be used to store and mange the client escret of the registered azure ad acpplication , then an `Azure Function` to renew the application's refresh token weekly.  
  
1. `Create an Azure Key Vault:` Follow the instructions in the Azure documentation to create an Azure Key Vault and grant access to your Azure AD application.

2. `Create a Secret in Azure Key Vault:` Use the Azure portal or Azure CLI to create a secret in the Azure Key Vault to store the client secret of your Azure AD application.

3. `Retrieve the Client Secret in an Azure Function:` Use an Azure Function to retrieve the client secret from the Azure Key Vault. You can use the Azure.Identity and Azure.Security.KeyVault.Secrets packages to authenticate and retrieve the secret from the Azure Key Vault.

4. `Renew the Refresh Token:` Use the Microsoft.Identity.Client package in the Azure Function to renew the refresh token of the Azure AD application. You can use the ConfidentialClientApplicationBuilder class to configure the Azure AD application with the client ID and client secret retrieved from the Azure Key Vault. Once the application is configured, you can use the AcquireTokenForClient method to acquire a new access token and refresh token for the application.

5. `Schedule the Azure Function:` Use Azure Functions to schedule the function to run weekly. You can use Azure Logic Apps or Azure Data Factory to trigger the function on a weekly basis. 

  
Here are templates for each, I'd advise customizing them to your setting.  
  
`Azure Key Vault Template`  
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "vaultName": {
            "type": "string",
            "metadata": {
                "description": "Name of the Key Vault"
            }
        },
        "applicationId": {
            "type": "string",
            "metadata": {
                "description": "Application ID of the Azure AD application"
            }
        }
    },
    "variables": {
        "accessPolicyObjectId": "[reference(concat('Microsoft.Web/sites/', variables('webAppName'), '/config/authsettings/list'), '2018-02-01', 'Full').name]",
        "accessPolicyResourceId": "[concat(subscription().id, '/providers/Microsoft.Web/sites/', variables('webAppName'))]"
    },
    "resources": [
        {
            "type": "Microsoft.KeyVault/vaults",
            "apiVersion": "2019-09-01",
            "name": "[parameters('vaultName')]",
            "location": "[resourceGroup().location]",
            "properties": {
                "enabledForDeployment": false,
                "enabledForDiskEncryption": false,
                "enabledForTemplateDeployment": true,
                "enableRbacAuthorization": true,
                "accessPolicies": [
                    {
                        "objectId": "[parameters('applicationId')]",
                        "tenantId": "[subscription().tenantId]",
                        "permissions": {
                            "secrets": [
                                "get",
                                "list"
                            ]
                        }
                    }
                ],
                "sku": {
                    "name": "standard",
                    "family": "A"
                }
            }
        }
    ],
    "outputs": {
        "vaultUri": {
            "type": "string",
            "value": "[reference(concat('Microsoft.KeyVault/vaults/', parameters('vaultName')), '2019-09-01').vaultUri]"
        }
    }
}
```  
  
    
`Azure Function Template`
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-08-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "appName": {
            "type": "string",
            "metadata": {
                "description": "Name of the Azure Function App"
            }
        },
        "keyVaultName": {
            "type": "string",
            "metadata": {
                "description": "Name of the Azure Key Vault"
            }
        },
        "applicationId": {
            "type": "string",
            "metadata": {
                "description": "Application ID of the Azure AD application"
            }
        }
    },
    "resources": [
        {
            "type": "Microsoft.Web/sites",
            "apiVersion": "2021-02-01",
            "name": "[parameters('appName')]",
            "location": "[resourceGroup().location]",
            "kind": "functionapp",
            "identity": {
                "type": "SystemAssigned"

```
