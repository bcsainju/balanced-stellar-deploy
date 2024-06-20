# balanced-stellar-deploy

# Deployment
> **_Assumptions:_**  The required contract binaries are at folders of specific names i.e. icon,stellar etc. Look at the scripts for the exact binary names.
## Steps:
1) Deploy xcall and connection contracts in icon
    ```sh icon.sh setupXcall```
2) Copy xcall address and deploy from all balanced contracts . Copy the deployment info after the deployment to a json file(deployments.json).
    ```json
        {
            "bnusd": "cx0e58a3939bdd27073e271fbfacd613a81ae904bb",
            "loan": "cxf24b6c2644116fc4c4925bbbfa4fc31bccf36aa1",
            "router": "cxc8d20fee85e8e89791f6a2f845bdc97b04ada157",
            "daofund": "cxd4a9e0bc994de95b9c4a7ed122a260393c748abf",
            "assetManager": "cx7f3e7e3c38a80d108afca152bc68c010b0e61644",
            "xcallManager": "cxa27243adae50dadc497142c4908f0e7fee62f8c5",
            "governance": "cxc7ac214f61aa4b5fc9a408e528249facdf58a56a",
            "baln": "cx411d47e0ac227246133f97f07ba9214fb32a7100"
        }
    ```
3) Deploy stellar xcall contracts
    ```sh stellar.sh setupXcall```
4) Setup Balanced contracts in stellar chain
    ```sh stellar.sh setupBaln```
5) Configure the stellar contracts to sync with deployment in icon
    ```sh icon.sh postSetup```

> **_NOTE:_**  The relayer should be up and running with proper configuration for below tests.


## Balanced Dollar Test(BnUSD) (Cross transfer)
### Setting up pre-requisites
#### Steps
- Deposit and borrow in icon
    ```sh icon.sh depositNBorrow```
- Borrow BnUSD from sICX
    ```sh icon.sh borrow```

### Transfer BnUSD from icon to stellar
```sh icon.sh transferBnUSD```

### Transfer BnUSD from stellar to icon
```sh stellar.sh xTransfer```


## Asset Manager test
### Deposit BnUSD in stellar AM
```sh stellar.sh depositBnUSD```

### Withdraw from icon
```sh icon.sh withdrawTo```

### Deposit rollback test in BnUSD (Cross Transfer)
#### stellar to icon
```sh stellar.sh invalidXTransfer```

#### icon to stellar
```sh icon.sh transferBnUSDInvalid```


### Deposit rollback test in AM
#### stellar to icon
```sh stellar.sh depositBnUSDInvalid```

#### icon to stellar
```sh icon.sh withdrawToInvalid```

