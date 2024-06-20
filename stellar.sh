#!/bin/bash
source const.sh
export ENDPOINT=https://soroban-testnet.stellar.org:443
export PASSPHRASE="Test SDF Network ; September 2015"

# export ENDPOINT=https://tt.net.solidwallet.io/stellar-rpc/rpc
# export PASSPHRASE="Standalone Network ; February 2017"
export ACCOUNT=SDFOICJI3PHUWHFARICCQS2A3W6BNGQVWQ6JDNYPH62VW6GWDBHDH7GE
export ADDRESS=$stellarAddress
# export NATIVE_ADDRESS=CDMLFMKMMD7MWZP3FKUBZPVHTUEDLSX4BYGYKH4GCESXYHS3IHQ4EIG4
export NATIVE_ADDRESS=CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC


usage() {
    echo "Usage: $0 []"
    exit 1
}

if [ $# -eq 1 ]; then
    CMD=$1
else
    usage
fi


function setupXcall() {
    local xcallContractAddr=$(soroban contract deploy --wasm $stellarXCallPath \
        --source-account $ACCOUNT \
        --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE")
    echo $xcallContractAddr > $stellarXcall

    local connectionAddr=$(soroban contract deploy --wasm $stellarConnectionPath \
        --source-account $ACCOUNT \
        --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE")
    echo $connectionAddr > $stellarConn    

     # configure xcall
    soroban contract invoke --id $xcallContractAddr \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        initialize --msg '{"network_id":"'$stellarConfName'", "sender":"'$ADDRESS'", "native_token":"'$NATIVE_ADDRESS'"}'

    # configure connection
    soroban contract invoke --id $connectionAddr \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        initialize --msg '{"xcall_address":"'$xcallContractAddr'", "native_token":"'$NATIVE_ADDRESS'", "relayer":"'$ADDRESS'"}'
}

function setupBaln() {
    xcallContractAddr=$(cat $stellarXcall)
    connAddr=$(cat $stellarConn)
    local bnUsdAddr=$(soroban contract deploy --wasm $stellarBnUsdPath \
        --source-account $ACCOUNT \
        --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE")
    echo $bnUsdAddr > $stellarBnUSD

    local assetMgr=$(soroban contract deploy --wasm $stellarAssetManagerPath \
        --source-account $ACCOUNT \
        --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE")
    echo $assetMgr > $stellarAssetlMgr
    
    local xcallManager=$(soroban contract deploy --wasm $stellarXcallManagerPath \
        --source-account $ACCOUNT \
        --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE")
    echo $xcallManager > $stellarXcallMgr
    xcallManager=$(cat $stellarXcallMgr)

    # configure xcallManager
    echo "Configuring Xcall Manager"
    soroban contract invoke --id $xcallManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        initialize --registry $xcallManager --admin $ADDRESS \
        --config '{"xcall":"'$xcallContractAddr'", "icon_governance":"'$iconConfName'/'$iconGov'"}' \
        --destinations [\"$iconConnAddress\"] \
        --sources [\"$connAddr\"]
        # --destinations \[\] \
        # --sources \[\]
        

    # # configure bnUSd
    echo "Configuring BnUSD" 
    bnUsdAddr=$(cat $stellarBnUSD)
    soroban contract invoke --id $bnUsdAddr \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        initialize --admin $ADDRESS \
        --config '{"xcall":"'$xcallContractAddr'", "xcall_manager":"'$xcallManager'","nid":"'$stellarConfName'","icon_bn_usd":"'$iconConfName'/'$iconBnUSD'"}'

    # configure asset manager
    echo "Configuring Asset manager and setting rate limit" 
    assetManager=$(cat $stellarAssetlMgr)
    soroban contract invoke --id $assetManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        initialize --registry $assetManager --admin $ADDRESS \
        --config '{"xcall":"'$xcallContractAddr'", "xcall_manager":"'$xcallManager'","native_address":"'$NATIVE_ADDRESS'","icon_asset_manager":"'$iconConfName'/'$iconAssetManager'"}'

    echo "Configuring Asset manager and setting rate limit" 
    # assetManager=$(cat $stellarAssetlMgr)
    # soroban contract invoke --id $assetManager \
    #     --source-account $ACCOUNT --rpc-url $ENDPOINT \
    #     --network-passphrase "$PASSPHRASE" -- \
    #     initialize --registry $assetManager --admin $ADDRESS \
    #     --config '{"xcall":"'$xcallContractAddr'", "xcall_manager":"'$xcallManager'","native_address":"'$bnUsdAddr'","icon_asset_manager":"'$iconConfName'/'$iconAssetManager'"}'


    # # configure rate limit
    # # period in seconds, percnetage max 1000
    soroban contract invoke --id $assetManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        configure_rate_limit --token_address $NATIVE_ADDRESS --period 5 \
        --percentage 500

    soroban contract invoke --id $assetManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
        configure_rate_limit --token_address $bnUsdAddr --period 5 \
        --percentage 500

}



function depositNative(){
    assetManager=$(cat $stellarAssetlMgr)
    soroban contract invoke --id $assetManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
         deposit --from $ADDRESS --token $NATIVE_ADDRESS \
        --amount 1000 --to "$iconConfName/$iconAddress"

    
}

function depositBnUSD(){
    echo "Depositing bnUSD"
    assetManager=$(cat $stellarAssetlMgr)
    bnUsdAddr=$(cat $stellarBnUSD)
    soroban contract invoke --id $assetManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
         deposit --from $ADDRESS --token $bnUsdAddr \
        --amount 1000 --to "$iconConfName/$iconAddress"
}

function depositBnUSDInvalid(){
    echo "Depositing bnUSD"
    assetManager=$(cat $stellarAssetlMgr)
    bnUsdAddr=$(cat $stellarBnUSD)
    soroban contract invoke --id $assetManager \
        --source-account $ACCOUNT --rpc-url $ENDPOINT \
        --network-passphrase "$PASSPHRASE" -- \
         deposit --from $ADDRESS --token $bnUsdAddr \
        --amount 5 --to "$iconConfName/invalidAddress"
}


function balance(){
    echo "XLM balance: "
    soroban contract invoke --id $NATIVE_ADDRESS \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- balance --id $ADDRESS

    assetManager=$(cat $stellarAssetlMgr)
    echo "Native token balance in AM: "
    soroban contract invoke --id $assetManager \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- balance_of --token $NATIVE_ADDRESS

    echo "BnUSD token balance: "
    bnUsdAddr=$(cat $stellarBnUSD)
    soroban contract invoke --id $bnUsdAddr \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- balance --id $ADDRESS
    
    echo "BnUSD token balance in AM: "
    soroban contract invoke --id $assetManager \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- balance_of --token $bnUsdAddr
}

function getNativeToken(){
    soroban lab token id --asset native --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT
}

function mintBnUSD(){
    bnUsdAddr=$(cat $stellarBnUSD)
    soroban contract invoke --id $bnUsdAddr \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- mint --to $ADDRESS --amount 10000
}

function xTransfer(){
    bnUsdAddr=$(cat $stellarBnUSD)    
    soroban contract invoke --id $bnUsdAddr \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- cross_transfer --from $ADDRESS --amount 1000 --to "$iconConfName/$iconAddress"
}

function invalidXTransfer(){
    bnUsdAddr=$(cat $stellarBnUSD)    
    soroban contract invoke --id $bnUsdAddr \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- cross_transfer --from $ADDRESS --amount 20 --to "$iconConfName/invalidAddress"
}

function executeRollBack(){
    bnUsdAddr=$(cat $stellarBnUSD)    
    soroban contract invoke --id $stellarXcallAddress \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- execute_rollback --sequence_no 5
}

function executeCall(){
    bnUsdAddr=$(cat $stellarBnUSD)    
    soroban contract invoke --id $stellarXcallAddress \
        --rpc-url $ENDPOINT --network-passphrase "$PASSPHRASE" \
        --source-account $ACCOUNT -- execute_call --sender GCX3TODZ2KEHYGD6HOQDRZVOUWNSQWP6OLYBIQ3XNPFKQ47G42H7WCGA --req_id 3 --data f8668e7843726f73735472616e73666572b569636f6e2e6c6f63616c2f6878623662353739316265306235656636373036336233633130623834306662383135313464623266649c7374656c6c61722e6c6f63616c2f696e76616c69644164647265737382271080
}

##########Main switch case ###############
case "$CMD" in
	setupXcall )
        setupXcall
  ;;       
  setupBaln )
        setupBaln
  ;;   
  depositNative )
        depositNative
  ;;
  depositBnUSD )
    depositBnUSD
  ;;
  balance )
    balance
  ;;  
  getNativeToken )
    getNativeToken
  ;;
   mint )
    mintBnUSD
  ;;
  xTransfer )
    xTransfer
  ;;
  invalidXTransfer )
    invalidXTransfer
  ;;
  executeRollBack )
    executeRollBack
  ;;
   executeCall )
    executeCall
  ;;
  depositBnUSDInvalid )
    depositBnUSDInvalid
  ;;
  * )
 
    echo "Error: unknown command: $CMD"
    usage
esac
