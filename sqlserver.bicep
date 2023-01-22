param location string = resourceGroup().location
param AppProfile string = 'Wordpress'
param serverName string
param databaseVersion string = '8.0'
param serverUsername string
param serverEdition string = 'GeneralPurpose'
param skuCode string = 'Standard_D2ds_v4'
@secure()
param serverPassword string
param storageSizeGB int = 32
param storageIops int = 1000
param storageAutoGrow string = 'Enabled'
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param vnetName string
param subnetForDb string
param privateDnsZoneNameForDb string
var privateDnsZoneNameForDbId=resourceId('Microsoft.Network/privateDnsZones', privateDnsZoneNameForDb)



resource Flexmysqlserver 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: serverName
  location: location
  tags: {
    AppProfile: AppProfile
  }
  sku: {
    tier: serverEdition
    name: skuCode
  }

  properties: {
    administratorLogin: serverUsername
    administratorLoginPassword: serverPassword
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }


    network: {
      privateDnsZoneResourceId: privateDnsZoneNameForDbId
      delegatedSubnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetForDb)
    }
    storage: {
      storageSizeGB: storageSizeGB
      iops: storageIops
      autoGrow: storageAutoGrow
    }
    version: databaseVersion
  }
}
