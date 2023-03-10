param
(
    [string]$name = "wpdemo$(Get-Random)",# Enter a base name for the resource.
	[string] $deploymentName = "wpdemo-$(Get-Random)",
    [string]$RGName = "${name}-rg",
    [string]$paramFileName = "./parameters.json",
    [string]$templateFileName = "./main.bicep",
    [string]$projectFolderName = "demosite",
    [string]$location= "eastus",
    # [string]$subscriptionId="$(az account list --query "[?isDefault].id" -o tsv)",
    [string]$subscriptionId="Enter your subscription id",
    # [string]$keyVaultName="${name}-kv"
    #[string]$serverPassword_Scrt=$(read-host -Prompt "Enter sql server password"),
	#[string]$wordpressPassword_Scrt=$(read-host -Prompt "Enter sql server password"),
	[string]$serverPassword=([xml](Get-Content env.xml)).root.SQLServerPassword,
    [string]$wordpressPassword=([xml](Get-Content env.xml)).root.WordPressPassword
)


# Set a default subscription for the current session.
# az account set --subscription $subscriptionId

# Create a resource group.
az group create --name $RGName --location $location

# az ad sp create-for-rbac --name "${name}-sp" --role contributor `
#  --scopes /subscriptions/$subscriptionId/resourceGroups/$RGName --create-cert 


# Create Key Vault and store secrets
# az keyvault create --name $keyVaultName --resource-group $RGName --location $location `
#  --enabled-for-template-deployment true
# echo $serverPassword 
# echo $wordpressPassword


#Get value from secureStrings 
#$serverPassword= [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($serverPassword_Scrt))
#$wordpressPassword= [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($wordpressPassword_Scrt))

# or you can also use the following command to get the value from secureStrings
#$serverPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($serverPassword_Scrt)
#$wordpressPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($wordpressPassword_Scrt)


# Deploy the template to the resource group
az deployment group create --resource-group $RGName --template-file $templateFileName `
    --parameters $paramFileName name=$name wordpressPassword=$wordpressPassword serverPassword=$serverPassword

# create azure file share for wordpress
# az storage share create --name "wpdemo-wpfiles" --account-name "wpdemostrgacc" --quota 5120

