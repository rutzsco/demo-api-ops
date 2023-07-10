@description('The name of the API Management service instance')
param apiManagementServiceName string

@description('The email address of the owner of the service')
@minLength(1)
param apiManagmentPublisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param apiManagmentPublisherName string

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  1
  2
])
param skuCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

param apiManagmentLoggingEventHubNamespaceName string
param apiManagmentLoggingEventHubName string

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: apiManagmentPublisherEmail
    publisherName: apiManagmentPublisherName
  }
}

resource loggingEventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: apiManagmentLoggingEventHubNamespaceName
}

resource loggingEventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' existing = {
  name: apiManagmentLoggingEventHubName
  parent: loggingEventHubNamespace
}


resource eventHubNamespaceName_eventHubName_Send 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  parent: loggingEventHub
  name: 'Send'
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource ehLoggerWithConnectionString 'Microsoft.ApiManagement/service/loggers@2022-04-01-preview' = {
  name: 'AdvancedLogger'
  parent: apiManagementService
  properties: {
    loggerType: 'azureEventHub'
    description: 'Event hub logger with connection string'
    credentials: {
      connectionString: eventHubNamespaceName_eventHubName_Send.listKeys().primaryConnectionString
      name: 'ApimEventHub'
    }
  }
}

