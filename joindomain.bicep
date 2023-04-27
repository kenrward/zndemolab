[
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
