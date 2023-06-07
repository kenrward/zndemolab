$rg = "ZN-PARTNER-LAB"
az group create --name $rg --location eastus  

az deployment group create -g $rg  `
    --template-file main.bicep `
    --parameters adminUsername=znadmin `
        domainFQDN=zxdemo.local
