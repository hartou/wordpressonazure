// This template deploys a Wordpress site with a MySQL database, a CDN endpoint, a storage account and a virtual network.

//param baseName string
param name string
param location string
param hostingPlanName string = '${name}-appserviceplan'
param sku string = 'PremiumV2'
param skuCode string = 'P1V2'
param kind string = 'linux'
param reserved bool = true
param alwaysOn bool = true
param linuxFxVersion string
param dockerRegistryUrl string
param storageSizeGB int = 128
param storageIops int = 700
param storageAutoGrow string  = 'Enabled'
param backupRetentionDays int = 7
param geoRedundantBackup string = 'disabled'
param charset string = 'utf8'
param collation string = 'utf8_general_ci'
param serverName string= '${name}-mysql'
param sqlServerUsername string

@secure()
param sqlServerPassword string
param wordpressTitle string
param wordpressAdminEmail string
param wordpressUsername string

@secure()
param wordpressPassword string
param wpLocaleCode string = 'en_US'
param cdnProfileName string = '${name}-cdnprofile'
param cdnEndpointName string  = '${name}-cdnendpoint'
param cdnType string = 'Standard_Microsoft'
param storageAccountType string = 'Standard_RAGRS'
param storageAccountKind string= 'StorageV2'
param accessTier string = 'Hot'
param minimumTlsVersion string = 'TLS1_2'
param supportsHttpsTrafficOnly bool = true
param allowBlobPublicAccess bool = true
param allowSharedKeyAccess bool = true
param allowCrossTenantReplication bool = true
param networkAclsBypass string  = 'AzureServices'
param networkAclsDefaultAction string = 'Allow'
param keySource string  = 'Microsoft.Storage'
param encryptionEnabled bool= true
param infrastructureEncryptionEnabled bool  = true
param blobContainerName string = toLower('${name}blob')
param blobPublicAccessLevel string = 'blob'
param vnetName string = '${name}-vnet'
param subnetForApp string= '${name}-subnet-app'
param subnetForDb string= '${name}-subnet-db'
param privateDnsZoneNameForDb string= '${name}-privatelink.mysql.database.azure.com'
param cdnOriginHostHeader string = '${name}.azurewebsites.net'

// BYOS: Bring Your Own Storage
//param BYOS_mountName string = 'BYOS'
//param BYOS_mountPath string = '/BYOS'
//param AzureStorage_AccountName string
//param AzureStorage_ShareName string

@secure()
param AzureStorage_AccountKey string
// tags
var tags = {
  AppProfile: 'Wordpress'
  AppType: 'Web'
}

var databaseName = '${name}-wpdb'
var storageAccountName  = toLower('${name}sa')
var databaseVersion = '5.7'
var vnetAddress = '10.0.0.0/23'
var subnetAddressForApp = '10.0.0.0/24'
var subnetAddressForDb = '10.0.1.0/24'
var storageAccountId = storageAccount.id

// resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing= {
//   name: name
// }
module app_service 'appservice.bicep'= {
  name: 'appservice'
  params: {
    name: name
    location: location
    dockerRegistryUrl: dockerRegistryUrl
    serverName: serverName
    sqlServerUsername: sqlServerUsername
    sqlServerPassword: sqlServerPassword
    wordpressTitle: wordpressTitle
    wordpressAdminEmail: wordpressAdminEmail
    wordpressUsername: wordpressUsername
    wordpressPassword: wordpressPassword
    wpLocaleCode: wpLocaleCode
    cdnEndpointName: cdnEndpointName
    databaseName: databaseName
    storageAccountName: storageAccountName
    storageAccountId: storageAccountId
    linuxFxVersion: linuxFxVersion
    hostingPlanName: hostingPlanName
    blobContainerName: blobContainerName
    // BYOS: Bring Your Own Storage
    BYOS_mountName: BYOS_mountName
    BYOS_mountPath: BYOS_mountPath
    AzureStorage_AccountName: AzureStorage_AccountName
    AzureStorage_ShareName: AzureStorage_ShareName
    AzureStorage_AccountKey: AzureStorage_AccountKey

  }
  dependsOn: [    
    mysqlserver
    serverName_database
    storageAccountName_default_blobContainer
  ]

}


resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  kind: kind
  tags: tags
  properties: {
    elasticScaleEnabled: false
    reserved: reserved
  }
  
  sku: {
    tier: sku
    name: skuCode
  }
  dependsOn: [
    mysqlserver
  ]
}

module mysqlserver 'sqlserver.bicep'={
  name: 'mysqlserver'
  params: {
    serverName: serverName
    location: location
    databaseVersion: databaseVersion
    sqlServerUsername: sqlServerUsername
    // sqlServerPassword: kv.getSecret(sqlServerPassword)
    sqlServerPassword: sqlServerPassword

    storageSizeGB: storageSizeGB
    storageIops: storageIops
    storageAutoGrow: storageAutoGrow
    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup
    vnetName: vnetName
    subnetForDb: subnetForDb
    privateDnsZoneNameForDb: privateDnsZoneNameForDb
  }
  dependsOn: [
    privateDnsZoneNameForDb_privateDnsZoneNameForDb_vnetlink
  ]
}

resource serverName_database 'Microsoft.DBforMySQL/flexibleServers/databases@2021-05-01' = {
  name: '${serverName}/${databaseName}'
  properties: {
    charset: charset
    collation: collation
  }
  dependsOn: [
    mysqlserver
  ]
}
// resource frontdoor 'Microsoft.network/frontdoors@2021-04-01' existing= {
//   name: name
// }
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  location: location
  name: vnetName
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnetForApp
        properties: {
          addressPrefix: subnetAddressForApp
          delegations: [
            {
              name: 'dlg-appService'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: subnetForDb
        properties: {
          addressPrefix: subnetAddressForDb
          delegations: [
            {
              name: 'dlg-database'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}

resource privateDnsZoneNameForDb_resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneNameForDb
  location: 'global'
  tags: {
    AppProfile: 'Wordpress'
  }
  dependsOn: []
}

resource privateDnsZoneNameForDb_privateDnsZoneNameForDb_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneNameForDb_resource
  name: '${privateDnsZoneNameForDb}-vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: true
  }
}

resource app_virtualNetwork 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  name: '${name}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetForApp)
  }
  dependsOn: [
    app_service
    privateDnsZoneNameForDb_privateDnsZoneNameForDb_vnetlink
  ]
}

resource name_web 'Microsoft.Web/sites/config@2022-03-01' = {
  name: '${name}/web'
  properties: {
    alwaysOn: alwaysOn
  }
  dependsOn: [
    app_service
    app_virtualNetwork
  ]
}

resource cdnProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: cdnProfileName
  location: 'Global'
  sku: {
    name: cdnType
  }
  tags: {
    AppProfile: 'Wordpress'
  }
  properties: {
  }
  dependsOn: [
    mysqlserver
  ]
}

resource cdnProfileName_cdnEndPoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' = {
  parent: cdnProfile
  name: cdnEndpointName
  location: 'Global'
  tags:tags

  properties: {
    isHttpAllowed: true
    isHttpsAllowed: true
    isCompressionEnabled: true
    contentTypesToCompress: [
      'application/eot'
      'application/font'
      'application/font-sfnt'
      'application/javascript'
      'application/json'
      'application/opentype'
      'application/otf'
      'application/pkcs7-mime'
      'application/truetype'
      'application/ttf'
      'application/vnd.ms-fontobject'
      'application/xhtml+xml'
      'application/xml'
      'application/xml+rss'
      'application/x-font-opentype'
      'application/x-font-truetype'
      'application/x-font-ttf'
      'application/x-httpd-cgi'
      'application/x-javascript'
      'application/x-mpegurl'
      'application/x-opentype'
      'application/x-otf'
      'application/x-perl'
      'application/x-ttf'
      'font/eot'
      'font/ttf'
      'font/otf'
      'font/opentype'
      'image/svg+xml'
      'text/css'
      'text/csv'
      'text/html'
      'text/javascript'
      'text/js'
      'text/plain'
      'text/richtext'
      'text/tab-separated-values'
      'text/xml'
      'text/x-script'
      'text/x-component'
      'text/x-java-source'
    ]
    origins: [
      {
        name: '${name}-azurewebsites-net'
        properties: {
          hostName: cdnOriginHostHeader
          httpPort: 80
          httpsPort: 443
          originHostHeader: cdnOriginHostHeader
          priority: 1
          weight: 1000
          enabled: true
        }
      }
      {
        name: '${storageAccountName}-blob-core-windows-net'
        properties: {
          hostName: '${storageAccountName}.blob.${environment().suffixes.storage}'
          httpPort: 80
          httpsPort: 443
          originHostHeader: '${storageAccountName}.blob.${environment().suffixes.storage}'
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    originGroups: [
      {
        name: 'blob-origin-group'
        properties: {
          origins: [
            {
              id: resourceId('Microsoft.Cdn/profiles/endpoints/origins', cdnProfileName, cdnEndpointName, '${storageAccountName}-blob-core-windows-net')
            }
          ]
        }
      }
      {
        name: 'app-origin-group'
        properties: {
          origins: [
            {
              id: resourceId('Microsoft.Cdn/profiles/endpoints/origins', cdnProfileName, cdnEndpointName, '${name}-azurewebsites-net')
            }
          ]
        }
      }
    ]
    defaultOriginGroup: {
      id: resourceId('Microsoft.Cdn/profiles/endpoints/originGroups', cdnProfileName, cdnEndpointName, 'blob-origin-group')
    }
    geoFilters: []
    deliveryPolicy: {
      rules: [
        {
          name: 'originOverrideRule'
          order: 1
          conditions: [
            {
              name: 'UrlPath'
              parameters: {
                typeName: 'DeliveryRuleUrlPathMatchConditionParameters'
                operator: 'BeginsWith'
                negateCondition: true
                matchValues: [
                  '${blobContainerName}/wp-content/uploads/'
                ]
                transforms: [
                  'Lowercase'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'OriginGroupOverride'
              parameters: {
                typeName: 'DeliveryRuleOriginGroupOverrideActionParameters'
                originGroup: {
                  id: resourceId('Microsoft.Cdn/profiles/endpoints/originGroups', cdnProfileName, cdnEndpointName, 'app-origin-group')
                }
              }
            }
            {
              name: 'UrlRewrite'
              parameters: {
                typeName: 'DeliveryRuleUrlRewriteActionParameters'
                sourcePattern: '/${blobContainerName}/'
                destination: '/'
                preserveUnmatchedPath: true
              }
            }
          ]
        }
      ]
    }
  }
  dependsOn: [
    app_service
    storageAccountName_default_blobContainer
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  properties: {
    accessTier: accessTier
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      ipRules: []
    }
    encryption: {
      keySource: keySource
      services: {
        blob: {
          enabled: encryptionEnabled
        }
        file: {
          enabled: encryptionEnabled
        }
        table: {
          enabled: encryptionEnabled
        }
        queue: {
          enabled: encryptionEnabled
        }
      }
      requireInfrastructureEncryption: infrastructureEncryptionEnabled
    }
  }
  kind: storageAccountKind
  tags: {
    AppProfile: 'Wordpress'
  }
  sku: {
    name: storageAccountType
  }
  dependsOn: [
    mysqlserver
  ]
}

resource storageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    restorePolicy: {
      enabled: false
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    changeFeed: {
      enabled: false
    }
    isVersioningEnabled: false
  }
}

resource storageAccountName_default_blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccountName}/default/${blobContainerName}'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    metadata: {
    }
    publicAccess: blobPublicAccessLevel
  }
  dependsOn: [
    storageAccountName_default
    storageAccount
  ]
}

