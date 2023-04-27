@description('The name of the new lab instance to be created')
param labName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the vm to be created.')
param vmSize string = 'Standard_B2ms'

@description('The username for the local account that will be created on the new vm.')
param userName string

@description('Domain name for the new domain.')
param domainName string

@description('Domain FQDN name for the new domain.')
param domainFQDN string

@description('Domain OU Path.')
param DomainOUPath string = ''

@description('The password for the local account that will be created on the new vm.')
@secure()
param password string

param labVirtualNetworkId string

param vmName string

var labSubnetName = '${labVirtualNetworkName}subnet'
var labVirtualNetworkName = 'dtl${labName}'
var domainAdmin = '${domainName}\\${userName}'

resource labTS 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  name: vmName
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
    artifacts: [
      {
        artifactId: resourceId('Microsoft.DevTestLab/labs/artifactSources/artifacts', labName, 'public repo', 'windows-domain-join-new')
        artifactTitle: 'windows-domain-join-new'
        parameters: [
          {
            name: 'domainAdminUsername'
            value: domainAdmin
          }
          {
            name: 'domainToJoin'
            value: domainFQDN
          }
          {
            name: 'domainAdminPassword'
            value: password
          }
          {
            name: 'ouPath'
            value: DomainOUPath
          }
        ]
      }
    ]
    size: vmSize
    allowClaim: false
    galleryImageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      osType: 'Windows'
      version: 'latest'
    }
  }
}
