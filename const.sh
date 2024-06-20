# evm configs
evmXcallMgr=evm/evm-xcall-mgr.env
evmAssetlMgr=evm/evm-asset-mgr.env
evmBnUSD=evm/evm-bnusd.env

# icon configs
iconNid=0x3
iconConfName="icon.local"
iconXcall=icon/icon-xcall.env
iconConn=icon/icon-conn.env
iconAddress=hxb6b5791be0b5ef67063b3c10b840fb81514db2fd

iconXcallAddress=$(cat $iconXcall)
iconConnAddress=$(cat $iconConn)

iconGov=$(cat deployments.json| jq -r .governance)
iconBnUSD=$(cat deployments.json| jq -r .bnusd)
iconAssetManager=$(cat deployments.json| jq -r .assetManager)
iconXcallManager=$(cat deployments.json| jq -r .xcallManager)
iconDaoFund=$(cat deployments.json| jq -r .daofund)
iconBalnRouter=$(cat deployments.json| jq -r .router)
iconBalnLoans=$(cat deployments.json| jq -r .loan)

# stellar configs
stellarConfName="stellar.local"
stellarXCallPath=stellar/xcall.wasm
stellarConnectionPath=stellar/centralized_connection.wasm
stellarAssetManagerPath=stellar/asset_manager.wasm
stellarBnUsdPath=stellar/balanced_dollar.wasm
stellarXcallManagerPath=stellar/xcall_manager.wasm

stellarXcall=stellar/stellar-xcall.env
stellarConn=stellar/stellar-conn.env
stellarXcallAddress=$(cat $stellarXcall)
stellarConnAddress=$(cat $stellarConn)
stellarXcallMgr=stellar/stellar-xcall-mgr.env
stellarAssetlMgr=stellar/stellar-asset-mgr.env
stellarBnUSD=stellar/stellar-bnusd.env
stellarXcallMgrAddress=$(cat $stellarXcallMgr)
stellarAddress=GCX3TODZ2KEHYGD6HOQDRZVOUWNSQWP6OLYBIQ3XNPFKQ47G42H7WCGA



