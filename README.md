# Zero Networks Azure DevTest Lab Deployment

To run this, first create a Resource Group

`az group create --name ZN-Demo-Lab --location eastus`

Then deploy the bicep file

`az deployment group create --resource-group ZN-Demo-Lab --template-file main.bicep --parameters labName=zn-demo dnsPrefix=zndemo userName=ken domainName=zndemo domainFQDN=zndemo.com`
