
param  name string
param  location string
param serverName string
param databaseName string
param sqlServerUsername string

@secure()
param sqlServerPassword string

param wordpressAdminEmail string
param  wordpressUsername string
@secure()
param  wordpressPassword string


param  dockerRegistryUrl string
param  linuxFxVersion string
param  wordpressTitle string
param  wpLocaleCode string
param  cdnEndpointName string
param  storageAccountName string
param  blobContainerName string
param  storageAccountId string
param  hostingPlanName string
param AppProfile string='Wordpress'

// // BYOS : Bring Your Own Storage
// param BYOS_mountName string
// param BYOS_mountPath string
// param AzureStorage_AccountName string
// param AzureStorage_ShareName string
// @secure()
// param AzureStorage_AccountKey string


var hostingPlanid=resourceId('Microsoft.Web/serverfarms', hostingPlanName)


resource app_service 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: {
    AppProfile: AppProfile
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'true'
        }
        {
          name: 'DATABASE_HOST'
          value: '${serverName}.mysql.database.azure.com'
        }
        {
          name: 'DATABASE_NAME'
          value: databaseName
        }
        {
          name: 'DATABASE_USERNAME'
          value: sqlServerUsername
        }
        {
          name: 'DATABASE_PASSWORD'
          value: sqlServerPassword
        }
        {
          name: 'WORDPRESS_ADMIN_EMAIL'
          value: wordpressAdminEmail
        }
        {
          name: 'WORDPRESS_ADMIN_USER'
          value: wordpressUsername
        }
        {
          name: 'WORDPRESS_ADMIN_PASSWORD'
          value: wordpressPassword
        }
        {
          name: 'WORDPRESS_TITLE'
          value: wordpressTitle
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '900'
        }
        {
          name: 'WORDPRESS_LOCALE_CODE'
          value: wpLocaleCode
        }
        {
          name: 'SETUP_PHPMYADMIN'
          value: 'true'
        }
        {
          name: 'CDN_ENABLED'
          value: 'true'
        }
        {
          name: 'CDN_ENDPOINT'
          value: '${cdnEndpointName}.azureedge.net'
        }
        {
          name: 'BLOB_STORAGE_ENABLED'
          value: 'true'
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'BLOB_CONTAINER_NAME'
          value: blobContainerName
        }
        {
          name: 'STORAGE_ACCOUNT_KEY'
          value: listKeys(storageAccountId, '2019-04-01').keys[0].value
        }
        {
          name: 'BLOB_STORAGE_URL'
          value: '${storageAccountName}.blob.${environment().suffixes.storage}'
        }
      ]
      connectionStrings: []
      linuxFxVersion: linuxFxVersion
      vnetRouteAllEnabled: true
      // azureStorageAccounts: {
      //   '${BYOS_mountName}': {
      //     mountPath: BYOS_mountPath
      //     accountName: AzureStorage_AccountName
      //     type: 'AzureFiles'
      //     shareName: AzureStorage_ShareName
      //     accessKey: AzureStorage_AccountKey
      //   }
      // }
    }

    serverFarmId:hostingPlanid
    clientAffinityEnabled: false
  }
}
