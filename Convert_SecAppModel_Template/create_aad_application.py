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
