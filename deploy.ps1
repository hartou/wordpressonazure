param
(
    [string]$name = "wpdemov5",# Enter the name of the resource and the deployment.
    [string]$RGName = "${name}-rg",
    [string]$paramFileName = "./parameters.json",
    [string]$templateFileName = "./main.bicep",
    [string]$projectFolderName = "ordojsite",
    [string]$location= "eastus",
    # [string]$subscriptionId="$(az account list --query "[?isDefault].id" -o tsv)",
    [string]$subscriptionId="Enter your subscription id",
    # [string]$keyVaultName="${name}-kv"
    [string]$serverPassword=$(read-host -Prompt "Enter a Password"),
    [string]$wordpressPassword=$(read-host -Prompt "Enter wordpress password" )
)
# Set a default subscription for the current session.
# az account set --subscription $subscriptionId

# Create a resource group.
az group create --name $RGName --location $location

# az ad sp create-for-rbac --name "${name}-sp" --role contributor `
#  --scopes /subscriptions/$subscriptionId/resourceGroups/$RGName --create-cert 

# # Create Key Vault and store secrets
# az keyvault create --name $keyVaultName --resource-group $RGName --location $location `
#  --enabled-for-template-deployment true
# echo $serverPassword 
# echo $wordpressPassword
# # Deploy the template
az deployment group create --resource-group $RGName --template-file $templateFileName `
--parameters $paramFileName name=$name wordpressPassword=$wordpressPassword serverPassword=$serverPassword

# # create azure file share for wordpress
# #az storage share create --name "wpdemo-wpfiles" --account-name "wpdemostrgacc" --quota 5120

