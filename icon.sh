#!/bin/bash

source const.sh
export ENDPOINT=https://tt.net.solidwallet.io/jvm-rpc/api/v3/
export DEBUG_ENDPOINT=https://tt.net.solidwallet.io/jvm-rpc/api/v3d/

export ADDRESS=hxb6b5791be0b5ef67063b3c10b840fb81514db2fd

# export STELLAR_NATIVE_ADDRESS=CDMLFMKMMD7MWZP3FKUBZPVHTUEDLSX4BYGYKH4GCESXYHS3IHQ4EIG4
export STELLAR_NATIVE_ADDRESS=CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC
xcallPath=icon/xcall-latest.jar
connPath=icon/centralized-connection-latest.jar


otherAssetManager=$(cat $stellarAssetlMgr)
otherBnUSD=$(cat $stellarBnUSD)
otherConn=$(cat $stellarConn)
confName=$stellarConfName
confDenom="BnUSD"

wallet=icon/godwallet.json
password=gochain


usage() {
    echo "Usage: $0 []"
    exit 1
}

if [ $# -eq 1 ]; then
    CMD=$1
else
    usage
fi


function printDebugTrace() {
	local txHash=$1
        echo $txHash
        sleep 4
	goloop debug trace --uri $DEBUG_ENDPOINT $txHash | jq -r .
}

function wait_for_it() {
	local txHash=$1
	echo "Txn Hash: "$1
	
	status=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .status)
	if [ $status == "0x1" ]; then
        echo "Successful"
    else
    	echo $status
    	read -p "Print debug trace? [y/N]: " proceed
    	if [[ $proceed == "y" ]]; then
    		printDebugTrace $txHash
    	fi
    	exit 0
    fi
}



function configureStellarXallMgr(){

    # sending fund to governance
    local txHash=$(goloop rpc sendtx transfer \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconGov \
	    --value 10000000000000000000 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	echo $txHash
	wait_for_it $txHash
    #  RLP encode replacing second param with hex address of other and third param with hex address of icon Conn contract
    # ["0x436f6e66696775726550726f746f636f6c73",["0x4343565949545734464e41524e50464d3545485558594f574f37465749445a4332364659353737484b534f53574233534334334159495658"],["0x637865646130386538663630353566346534613939636636363036393232356631626434613439633662"]]

    input='[
                {
                    "address": "'$iconXcallAddress'",
                    "method": "sendCallMessage",
                    "value":10000000000000000000,
                    "parameters": [
                        {
                            "type": "String",
                            "value": "'$stellarConfName'/'$stellarXcallMgrAddress'"
                        },
                        {
                            "type": "bytes",
                            "value": "0xf87b92436f6e66696775726550726f746f636f6c73f83ab8384343565949545734464e41524e50464d3545485558594f574f37465749445a4332364659353737484b534f53574233534334334159495658ebaa637865646130386538663630353566346534613939636636363036393232356631626434613439633662"
                        },
                        {
                            "type": "bytes",
                            "value": ""
                        },
                        {
                            "type": "String[]",
                            "value": ["'$iconConnAddress'"]
                        },
                        {
                            "type": "String[]",
                            "value": ["'$stellarConnAddress'"]
                        }
                    ]
                }
            ]'


    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000000000 \
	    --to $iconGov \
	    --method execute \
	    --param transactions="$input"\
        --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	echo $txHash
	wait_for_it $txHash

}
function configure() {

    input='[
                {
                    "address": "'$iconXcallManager'",
                    "method": "configureProtocols",
                    "parameters": [
                        {
                            "type": "String",
                            "value": "'$confName'"
                        },
                        {
                            "type": "String[]",
                            "value": ["'$iconConnAddress'"]
                        },
                        {
                            "type": "String[]",
                            "value": ["'$otherConn'"]
                        }
                    ]
                },
                {
                    "address": "'$iconAssetManager'",
                    "method": "addSpokeManager",
                    "parameters": [
                        {
                            "type": "String",
                            "value": "'$confName'/'$otherAssetManager'"
                        }
                    ]
                },
                {
                    "address": "'$iconAssetManager'",
                    "method": "deployAsset",
                    "parameters": [
                        {
                            "type": "String",
                            "value": "'$confName'/'$otherBnUSD'"
                        },
                        {
                            "type": "String",
                            "value": "'$confDenom'"
                        },
                        {
                            "type": "String",
                            "value": "'$confDenom'"
                        },
                        {
                            "type": "int",
                            "value": 9
                        }
                    ]
                },
                {
                    "address": "'$iconBnUSD'",
                    "method": "addChain",
                    "parameters": [
                        {
                            "type": "String",
                            "value": "'$confName'/'$otherBnUSD'"
                        },
                        {
                            "type": "int",
                            "value": "100000000000000000000000"
                        }
                    ]
                },
                {
                    "address": "'$iconDaoFund'",
                    "method": "setXCallFeePermission",
                    "parameters": [
                        {
                            "type": "Address",
                            "value": "'$iconAssetManager'"
                        },
                        {
                            "type": "String",
                            "value": "'$confName'"
                        },
                        {
                            "type": "boolean",
                            "value": true
                        }
                    ]
                },
                {
                    "address": "'$iconDaoFund'",
                    "method": "setXCallFeePermission",
                    "parameters": [
                        {
                            "type": "Address",
                            "value": "'$iconBnUSD'"
                        },
                        {
                            "type": "String",
                            "value": "'$confName'"
                        },
                        {
                            "type": "boolean",
                            "value": true
                        }
                    ]
                },
                {
                    "address": "'$iconDaoFund'",
                    "method": "setXCallFeePermission",
                    "parameters": [
                        {
                            "type": "Address",
                            "value": "'$iconBalnRouter'"
                        },
                        {
                            "type": "String",
                            "value": "'$confName'"
                        },
                        {
                            "type": "boolean",
                            "value": true
                        }
                    ]
                },
                {
                    "address": "'$iconDaoFund'",
                    "method": "setXCallFeePermission",
                    "parameters": [
                        {
                            "type": "Address",
                            "value": "'$iconBalnLoans'"
                        },
                        {
                            "type": "String",
                            "value": "'$confName'"
                        },
                        {
                            "type": "boolean",
                            "value": true
                        }
                    ]
                }
            ]'


    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconGov \
	    --method execute \
	    --param transactions="$input"\
        --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	echo $txHash
	wait_for_it $txHash
}


function configs(){
    echo "::::::::::::::spokes:::::::::::::::::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getSpokes
    
    echo "::::::::::::::Assets:::::::::::::::::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssets


    echo "::::::::::::::Assets Deposits:::::::::::::::::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssetDeposit \
        --param tokenNetworkAddress="$stellarconfName/$stellarBnUSD"

    echo "::::::::::::::Assets Deposits:::::::::::::::::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssetDeposit \
        --param tokenNetworkAddress="$stellarconfName/$STELLAR_NATIVE_ADDRESS"


    echo ":::Governance external addresses::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconGov \
	    --method getAddresses 

    echo ":::Baln Loan Asset Tokens::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBalnLoans \
	    --method getAssetTokens 

     echo ":::Baln Loan Collateral Tokens::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBalnLoans \
	    --method getCollateralTokens 




     echo ":::Baln Loan Collateral Tokens::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBalnLoans \
	    --method getAvailableAssets 
    
    echo "\n::::::::::::::::protocols:::::::::::::::::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconXcallManager \
	    --method getProtocols \
        --param nid=$confName

    echo "\n::::::::::::::::Connected Chains:::::::::::::::::"
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBnUSD \
	    --method getConnectedChains


    echo "\n::::::::::::::::Connected Chains:::::::::::::::::"
    goloop rpc call \
                --uri $ENDPOINT  \
                --to $iconBnUSD \
                --method totalSupply

    echo "\n::::::::::::::::xTotalSupply :::::::::::::::::"
    goloop rpc call \
            --uri $ENDPOINT  \
            --to $iconBnUSD \
            --method xTotalSupply

    echo "\n::::::::::::::::xSupply required for cross transfers(must be >0 for cross transfers to icon):::::::::::::::::"
     goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBnUSD \
	    --method xSupply \
        --param net="$stellarConfName"
        
}

function setupXcall(){
    local txHash=$(goloop rpc sendtx deploy $xcallPath  \
        --key_store $wallet \
	    --key_password $password \
        --step_limit 5000000000 --content_type application/java \
        --params '{"networkId":"'$iconConfName'"}' \
        --uri $ENDPOINT \
        --nid $iconNid | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
    iconXcallAddress=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .scoreAddress)
    echo "Xcall deployed at $iconXcallAddress"
	echo $iconXcallAddress > $iconXcall

    local txHash=$(goloop rpc sendtx deploy $connPath  \
        --key_store $wallet \
	    --key_password $password \
        --step_limit 5000000000 --content_type application/java \
        --params '{"_xCall":"'$iconXcallAddress'","_relayer":"'$ADDRESS'"}' \
        --uri $ENDPOINT \
        --nid $iconNid | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
    iconConnAddress=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .scoreAddress)
    echo "connection deployed at $iconConnAddress"
	echo $iconConnAddress > $iconConn

    # local txHash=$(goloop rpc sendtx call \
    #         --uri $ENDPOINT  \
    #         --nid 3 \
    #         --step_limit 10000000000000000 \
    #         --to $iconXcallAddress \
    #         --method setDefaultConnection \
    #         --param _nid="$iconConfName"\
    #         --param _connection="$iconConnAddress"\
    #         --key_store $wallet \
    #         --key_password $password | jq -r .)
    #     sleep 2
    #     echo $txHash
    #     wait_for_it $txHash
}






function withdrawTo(){
    local assetKey=$(
        goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssets | jq -r 'to_entries[] | select(.key | startswith("stellar.local/'$otherBnUSD'")) | .value')

    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconAssetManager \
	    --method withdrawTo \
	    --param asset="$assetKey" \
        --param to="$stellarConfName/$stellarAddress" \
        --param amount=100\
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash    
}

function withdrawToInvalid(){
    local assetKey=$(
        goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssets | jq -r 'to_entries[] | select(.key | startswith("stellar.local/'$otherBnUSD'")) | .value')

    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconAssetManager \
	    --method withdrawTo \
	    --param asset="$assetKey" \
        --param to="$stellarConfName/invalidAddress" \
        --param amount=10\
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash    
}

function withdrawNativeTo(){
    local assetKey=$(
        goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssets | jq -r 'to_entries[] | select(.key | startswith("stellar.local/CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC")) | .value')

    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconAssetManager \
	    --method withdrawTo \
	    --param asset="$assetKey" \
        --param to="$stellarConfName/$stellarAddress" \
        --param amount=100\
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash    
}

function depositNBorrow(){
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconBalnLoans \
	    --method depositAndBorrow \
        --value 100000000000000000000 \
        --param _amount=100000000000000000000 \
        --param _value=100000000000000000000 \
        --param _asset=$iconBnUSD \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash  
}


function addCollateral(){
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
        --nid 3 \
        --step_limit 10000000000 \
	    --to $iconGov \
	    --method addCollateral \
        --param  _token_address=$iconBnUSD \
        --param _active=0x1 \
        --param _peg=USD \
        --param _lockingRatio=5 \
        --param _liquidationRatio=5 \
        --param _debtCeiling=40 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
}


function borrow(){
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconBalnLoans \
	    --method borrow \
	    --param _collateralToBorrowAgainst=sICX \
        --param _assetToBorrow=bnUSD \
        --param _amountToBorrow=10000000000000000000 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash    
}


function returnAsset(){
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconBalnLoans \
	    --method returnAsset \
	    --param _collateralSymbol=sICX \
        --param _symbol=bnUSD \
        --param _value=5000000000000000000 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash    
}

function fix(){

     goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBalnLoans \
	    --method getAccountPositions \
        --param _owner=$ADDRESS
    
     goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBalnLoans \
	    --method getBalanceAndSupply \
        --param _owner=$ADDRESS \
        --param _name=Loans
}

function withDrawCollateral(){
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconBalnLoans \
	    --method withdrawCollateral \
	    --param _value=10 \
        --param _collateralSymbol=SICX \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
}

function transferBnUSD(){

     goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBnUSD \
	    --method xTotalSupply

    
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconBnUSD \
	    --method crossTransfer \
	    --param _to="$stellarConfName/$stellarAddress" \
        --param _value=1000 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
}

function transferBnUSDInvalid(){
     goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBnUSD \
	    --method xTotalSupply
    
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconBnUSD \
	    --method crossTransfer \
	    --param _to="$stellarConfName/invalidAddress" \
        --param _value=10000 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
}


function balance(){
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconBnUSD \
	    --method balanceOf \
        --param _owner=$ADDRESS
}

function nativeBalance(){
    local assetKey=$(
        goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $iconAssetManager \
	    --method getAssets | jq -r 'to_entries[] | select(.key | startswith("stellar.local/CDMLFMKMMD7MWZP3FKUBZPVHTUEDLSX4BYGYKH4GCESXYHS3IHQ4EIG4")) | .value')

    
    goloop rpc call \
	    --uri $ENDPOINT  \
	    --to $assetKey \
	    --method balanceOf \
        --param _owner=$ADDRESS
}

function executeRollBack(){
    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 10000000000\
	    --to $iconXcallAddress \
	    --method executeRollback \
	    --param _sn=7 \
        --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	echo $txHash
	wait_for_it $txHash
}


##########Main switch case ###############
case "$CMD" in
  postSetup )
    configure
  ;;
  setupXcall )
    setupXcall
  ;;
  deposit )
    deposit
  ;;
  configs )
    configs
    ;;
  withdrawTo )
    withdrawTo
  ;;
  depositNBorrow ) 
    depositNBorrow
    ;;
  addCollateral )
    addCollateral
    ;;
  withDrawCollateral )
    withDrawCollateral
    ;;
 borrow )
        borrow
    ;;
 returnAsset )
        returnAsset
    ;;
transferBnUSD )
        transferBnUSD
    ;;
 fix )
    fix
    ;;
balance )
    balance
    ;;
configureStellarXallMgr )
    configureStellarXallMgr
;;
withdrawNativeTo )
    withdrawNativeTo
;;
nativeBalance )
    nativeBalance
    ;;
transferBnUSDInvalid )
    transferBnUSDInvalid
    ;;
executeRollBack )
    executeRollBack
    ;;
withdrawToInvalid )
    withdrawToInvalid
;;
  * )
    echo "Error: unknown command: $CMD"
    usage
esac