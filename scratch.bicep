
module createTSServer 'modules/ts.bicep' = {
  scope: resourceGroup()
  name: 'CreateTS'
  params: {
    vmName: tsName
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labName: labName
    vmSize: vmSize
    location: location
    domainFQDN: domainFQDN
    domainName: domainName
    DomainOUPath: DomainOUPath
  }
  dependsOn: [
    labDC
  ]
}

module labTClient 'modules/ws.bicep' = {
  scope: resourceGroup()
  name: 'CreateClient'
  params: {
    vmName: srvName
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labName: labName
    vmSize: vmSize
    location: location
    domainFQDN: domainFQDN
    domainName: domainName
    DomainOUPath: DomainOUPath
  }
  dependsOn: [
    labDC
  ]
}

module labTSServer 'modules/ts.bicep' = {
  scope: resourceGroup()
  name: 'CreateLabSrv'
  params: {
    vmName: srvName
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labName: labName
    vmSize: vmSize
    location: location
    domainFQDN: domainFQDN
    domainName: domainName
    DomainOUPath: DomainOUPath
  }
  dependsOn: [
    labDC
  ]
}
