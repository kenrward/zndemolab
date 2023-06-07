@description('The name of the new lab instance to be created')
param labName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The username for the local account that will be created on the new vm.')
param userName string

@description('The password for the local account that will be created on the new vm.')
@secure()
param password string

var labSubnetName = '${labVirtualNetworkName}subnet'
var bastSubnetName = 'AzureBastionSubnet'
var labVirtualNetworkName = 'dtl${labName}'
var labVirtualNetworkId = labVirtualNetwork.id
var publicIpName = '${labName}pip'
var bastionHostName = '${labName}-bst'

resource lab 'Microsoft.DevTestLab/labs@2018-09-15' = {
  name: labName
  location: location
}

resource labVirtualNetwork 'Microsoft.DevTestLab/labs/virtualnetworks@2018-09-15' = {
  parent: lab
  name: labVirtualNetworkName
}

resource adminUser 'Microsoft.DevTestLab/labs/users@2018-09-15' = {
  name: userName
  location: location
  parent: lab
}

resource adminSecret 'Microsoft.DevTestLab/labs/users/secrets@2018-09-15' = {
  name: 'rootPwd'
  location: location
  parent: adminUser
  properties: {
    value: password
  }
}
resource publicIpAddressForBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: labVirtualNetworkUpdate::bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
}

resource labVirtualNetworkUpdate 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: labVirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '10.0.0.4' 
      ]
    }
    subnets: [
      {
        name: labSubnetName
        properties: {
          addressPrefix: '10.0.0.0/20'
        }
      }
      {
        name: bastSubnetName
        properties: {
          addressPrefix: '10.0.16.0/20'
        }
      }
    ]
  }
  resource bastionSubnet 'subnets' existing = {
    name: bastSubnetName
  }
  
  dependsOn: [
    labVirtualNetwork
  ]
}


output labId string = lab.id
output vnetid string = labVirtualNetworkId


