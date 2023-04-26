@description('The name of the new lab instance to be created')
param labName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the vm to be created.')
param dnsPrefix string

@description('The size of the vm to be created.')
param vmSize string = 'Standard_B2ms'

@description('The username for the local account that will be created on the new vm.')
param userName string

@description('Domain name for the new domain.')
param domainName string

@description('Domain FQDN name for the new domain.')
param domainFQDN string

@description('The password for the local account that will be created on the new vm.')
@secure()
param password string

var labSubnetName = '${labVirtualNetworkName}Subnet'
var labVirtualNetworkId = labVirtualNetwork.id
var labVirtualNetworkName = 'Dtl${labName}'
var dcName = '${dnsPrefix}dc01'
var tsName = '${dnsPrefix}trust01'
var srvName = '${dnsPrefix}srv01'
var clientName = '${dnsPrefix}client01'


resource lab 'Microsoft.DevTestLab/labs@2018-09-15' = {
  name: labName
  location: location
}

resource labVirtualNetwork 'Microsoft.DevTestLab/labs/virtualnetworks@2018-09-15' = {
  parent: lab
  name: labVirtualNetworkName
}

resource labDC 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  parent: lab
  name: dcName
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
    size: vmSize
    allowClaim: false
    artifacts: [
      {
        artifactId: 'create domain'
        artifactTitle: 'windows-CreateDomain'
        deploymentStatusMessage: 'string'
        installTime: 'string'
        parameters: [
          {
            name: 'DomainName'
            value: domainName
          }
          {
            name: 'DomainFQDN'
            value: domainFQDN
          }
          {
            name: 'SafeModePW'
            value: password
          }
        ]
      }
    ]
    galleryImageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      osType: 'Windows'
      version: 'latest'
    }
  }
}

resource labTS 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  parent: lab
  name: tsName
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
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

resource labSrv 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  parent: lab
  name: srvName
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
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

resource labClient 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  parent: lab
  name: clientName
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
    size: vmSize
    allowClaim: false
    galleryImageReference: {
      offer: 'windowsplustools'
      publisher: 'microsoftvisualstudio'
      sku: 'base-win11-gen2'
      osType: 'Windows'
      version: 'latest'
    }
  }
}

output labId string = lab.id
