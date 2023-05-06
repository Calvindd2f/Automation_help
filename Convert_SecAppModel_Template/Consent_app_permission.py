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
