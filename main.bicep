// Deployment parameters
@description('Location to depoloy all resources. Leave this value as-is to inherit the location from the parent resource group.')
param location string = resourceGroup().location

// Virtual network parameters
@description('Name for the virtual network.')
param virtualNetworkName string = 'VNET'

@description('Address space for the virtual network, in IPv4 CIDR notation.')
param virtualNetworkAddressSpace string = '10.0.0.0/16'

@description('Name for the default subnet in the virtual network.')
param subnetName string = 'Subnet'

@description('Address range for the default subnet, in IPv4 CIDR notation.')
param subnetAddressRange string = '10.0.0.0/24'

@description('Public IP address of your local machine, in IPv4 CIDR notation. Used to restrict remote access to resources within the virtual network.')
param allowedSourceIPAddress string = '0.0.0.0/0'

// Virtual machine parameters
@description('Name for the domain controller virtual machine.')
param domainControllerName string = 'DC01'

@description('Name for the workstation virtual machine.')
param workstationName string = 'WS01'

@description('Size for both the domain controller and workstation virtual machines.')
@allowed([
  'Standard_DS1_v2'
  'Standard_D2s_v3'
])
param virtualMachineSize string = 'Standard_DS1_v2'

// Domain parameters
@description('FQDN for the Active Directory domain (e.g. contoso.com).')
@minLength(3)
@maxLength(255)
param domainFQDN string = 'zndemo.local'

@description('Administrator username for both the domain controller and workstation virtual machines.')
@minLength(1)
@maxLength(20)
param adminUsername string = 'ZNTeamLab'

@description('Administrator password for both the domain controller and workstation virtual machines.')
@minLength(12)
@maxLength(123)
@secure()
param adminPassword string

var dcName = 'znlab-dc01'
var tsName = 'znlab-ts01'
var csName = 'znlab-cs01'
var srvName = 'znlab-srv01'
var rdpName = 'znlab-rdp01'

// Deploy the virtual network
module virtualNetwork 'modules/network.bicep' = {
  name: 'virtualNetwork'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    subnetName: subnetName
    subnetAddressRange: subnetAddressRange
    allowedSourceIPAddress: allowedSourceIPAddress
  }
}


// Deploy the domain controller
module domainController 'modules/vm.bicep' = {
  name: 'domainController'
  params: {
    location: location
    subnetId: virtualNetwork.outputs.subnetId
    vmName: domainControllerName
    vmSize: virtualMachineSize
    vmPublisher: 'MicrosoftWindowsServer'
    vmOffer: 'WindowsServer'
    vmSku: '2019-Datacenter'
    vmVersion: 'latest'
    vmStorageAccountType: 'StandardSSD_LRS'
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}


// Use PowerShell DSC to deploy Active Directory Domain Services on the domain controller
resource domainControllerConfiguration 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${domainControllerName}/Microsoft.Powershell.DSC'
  dependsOn: [
    domainController
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: 'https://github.com/joshua-a-lucas/BlueTeamLab/raw/main/scripts/Deploy-DomainServices.zip'
      ConfigurationFunction: 'Deploy-DomainServices.ps1\\Deploy-DomainServices'
      Properties: {
        domainFQDN: domainFQDN
        adminCredential: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:adminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
          adminPassword: adminPassword
      }
    }
  }
}

// Update the virtual network with the domain controller as the primary DNS server
module virtualNetworkDNS 'modules/network.bicep' = {
  name: 'virtualNetworkDNS'
  dependsOn: [
    domainControllerConfiguration
  ]
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    subnetName: subnetName
    subnetAddressRange: subnetAddressRange
    allowedSourceIPAddress: allowedSourceIPAddress
    dnsServerIPAddress: domainController.outputs.privateIpAddress
  }
}

// Deploy the workstation once the virtual network's primary DNS server has been updated to the domain controller
module workstation 'modules/vm.bicep' = {
  name: 'workstation'
  dependsOn: [
    virtualNetworkDNS
  ]
  params: {
    location: location
    subnetId: virtualNetwork.outputs.subnetId
    vmName: workstationName
    vmSize: virtualMachineSize
    vmPublisher: 'MicrosoftWindowsDesktop'
    vmOffer: 'Windows-10'
    vmSku: 'win10-21h2-pro'
    vmVersion: 'latest'
    vmStorageAccountType: 'StandardSSD_LRS'
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

// Use PowerShell DSC to join the workstation to the domain
resource workstationConfiguration 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${workstationName}/Microsoft.Powershell.DSC'
  dependsOn: [
    workstation
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: 'https://github.com/joshua-a-lucas/BlueTeamLab/raw/main/scripts/Join-Domain.zip'
      ConfigurationFunction: 'Join-Domain.ps1\\Join-Domain'
      Properties: {
        domainFQDN: domainFQDN
        computerName: workstationName
        adminCredential: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:adminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
          adminPassword: adminPassword
      }
    }
  }
}

//***************************************************************************************************************
// TRUST SERVER
//
// Deploy once the virtual network's primary DNS server has been updated to the domain controller
module trustServer 'modules/vm.bicep' = {
  name: 'trustserver'
  dependsOn: [
    virtualNetworkDNS
  ]
  params: {
    location: location
    subnetId: virtualNetwork.outputs.subnetId
    vmName: tsName
    vmSize: virtualMachineSize
    vmPublisher: 'MicrosoftWindowsServer'
    vmOffer: 'WindowsServer'
    vmSku: '2019-Datacenter'
    vmVersion: 'latest'
    vmStorageAccountType: 'StandardSSD_LRS'
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

// Use PowerShell DSC to join the workstation to the domain
resource trustServerConfiguration 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${trustServer}/Microsoft.Powershell.DSC'
  dependsOn: [
    trustServer
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: 'https://github.com/joshua-a-lucas/BlueTeamLab/raw/main/scripts/Join-Domain.zip'
      ConfigurationFunction: 'Join-Domain.ps1\\Join-Domain'
      Properties: {
        domainFQDN: domainFQDN
        computerName: tsName
        adminCredential: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:adminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
          adminPassword: adminPassword
      }
    }
  }
}


//***************************************************************************************************************
// RDP SERVER
//
// Deploy once the virtual network's primary DNS server has been updated to the domain controller
module rdpServer 'modules/vm.bicep' = {
  name: 'rdpserver'
  dependsOn: [
    virtualNetworkDNS
  ]
  params: {
    location: location
    subnetId: virtualNetwork.outputs.subnetId
    vmName: rdpName
    vmSize: virtualMachineSize
    vmPublisher: 'MicrosoftWindowsServer'
    vmOffer: 'WindowsServer'
    vmSku: '2019-Datacenter'
    vmVersion: 'latest'
    vmStorageAccountType: 'StandardSSD_LRS'
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

// Use PowerShell DSC to join the workstation to the domain
resource rdpServerConfiguration 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${rdpServer}/Microsoft.Powershell.DSC'
  dependsOn: [
    rdpServer
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: 'https://github.com/joshua-a-lucas/BlueTeamLab/raw/main/scripts/Join-Domain.zip'
      ConfigurationFunction: 'Join-Domain.ps1\\Join-Domain'
      Properties: {
        domainFQDN: domainFQDN
        computerName: rdpName
        adminCredential: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:adminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
          adminPassword: adminPassword
      }
    }
  }
}

//***************************************************************************************************************
// CONNECT SERVER
//
// Deploy once the virtual network's primary DNS server has been updated to the domain controller
module connectServer 'modules/vm.bicep' = {
  name: 'connectServer'
  dependsOn: [
    virtualNetworkDNS
  ]
  params: {
    location: location
    subnetId: virtualNetwork.outputs.subnetId
    vmName: csName
    vmSize: virtualMachineSize
    vmPublisher: 'canonical'
    vmOffer: '0001-com-ubuntu-server-lunar'
    vmSku: '23_04'
    vmVersion: 'latest'
    vmStorageAccountType: 'StandardSSD_LRS'
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

