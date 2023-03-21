
param name string

resource webApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: name
}

resource webAppPaths 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  kind: 'string'
  parent: webApp
  properties: {
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
      }
      {
        virtualPath: '/batchPGNetReminders'
        physicalPath: 'site\\wwwroot\\app_data\\Jobs\\Triggered\\PGNetReminders'
      }
      {
        virtualPath: '/batchPGNetSendReminders'
        physicalPath: 'site\\wwwroot\\app_data\\Jobs\\Triggered\\PGNetSendReminders'
      }
    ]
  }
}
