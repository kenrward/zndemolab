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

@description('Domain Admin name for the new domain.')
param domainAdmin string

@description('Domain OU Path.')
param DomainOUPath string

@description('The password for the local account that will be created on the new vm.')
@secure()
param password string

var labSubnetName = '${labVirtualNetworkName}subnet'
var labVirtualNetworkId = labVirtualNetwork.id
var labVirtualNetworkName = 'dtl${labName}'
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
    artifacts: [
      {
        artifactId: resourceId('Microsoft.DevTestLab/labs/artifactSources/artifacts', labName, 'public repo', 'windows-CreateDomain')
        artifactTitle: 'windows-CreateDomain'
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

resource labTS 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  parent: lab
  name: tsName
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


resource labClient 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  parent: lab
  name: clientName
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
      offer: 'windowsplustools'
      publisher: 'microsoftvisualstudio'
      sku: 'base-win11-gen2'
      osType: 'Windows'
      version: 'latest'
    }
  }
}



output labId string = lab.id
