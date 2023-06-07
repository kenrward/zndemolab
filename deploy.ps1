$rg = "pwZero04"
az group create --name $rg --location westus  

az deployment group create -g $rg  `
    --template-file dc.bicep `
    --parameters dnsPrefix=zxdemo `
        adminUsername=znadmin `
        domainName=zxdemo.local
