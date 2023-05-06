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
