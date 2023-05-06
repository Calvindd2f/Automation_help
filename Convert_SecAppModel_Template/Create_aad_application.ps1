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
