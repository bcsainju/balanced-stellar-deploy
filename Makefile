# ICON_BALANCE := $(shell (sh icon.sh balance))
# ICON_BALANCE_DEC := $(shell python -c 'print(int($(ICON_BALANCE), 16))')


# # Define a variable to capture the output of the shell script
# BALANCES_OUTPUT := $(shell sh stellar.sh balance)

# # Parse the balances from the output
# XLM_BALANCE := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$3}')
# NATIVE_TOKEN_BALANCE_AM := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$9}')
# BNUSD_TOKEN_BALANCE := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$13}')
# BNUSD_TOKEN_BALANCE_AM := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$19}')
BNUSD_TOKEN_BALANCE_AM := 0
PYTHON_SCRIPT := 'import sys; print(int(sys.argv[1].strip("\""))) if len(sys.argv) == 2 else sys.exit()'
.PHONY: all

# misc
# $(eval ICON_NATIVE_AM_BALANCE := $(shell (sh icon.sh nativeBalance)))
# $(eval ICON_NATIVE_AM_BALANCE_DEC := $(shell python -c 'print(int($(ICON_NATIVE_AM_BALANCE), 16))'))
# @echo icon native XLM balance is: $(ICON_NATIVE_AM_BALANCE_DEC)

print-balance:
	$(eval ICON_BALANCE := $(shell (sh icon.sh balance)))
	$(eval ICON_BALANCE_DEC := $(shell python -c 'print(int($(ICON_BALANCE), 16))'))
	$(eval BALANCES_OUTPUT := $(shell sh stellar.sh balance))
	$(eval XLM_BALANCE := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$3}'))
	$(eval NATIVE_TOKEN_BALANCE_AM := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$9}'))
	$(eval BNUSD_TOKEN_BALANCE := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$13}'))
	$(eval BNUSD_TOKEN_BALANCE_AM := $(shell echo '$(BALANCES_OUTPUT)' | awk '{print $$19}'))
	@echo icon BnUSD balance is: $(ICON_BALANCE_DEC)

	@echo stellar XLM balance is: $(XLM_BALANCE)
	@echo stellar XLM balance AM  is: $(NATIVE_TOKEN_BALANCE_AM)
	@echo stellar bnUSD balance is: $(BNUSD_TOKEN_BALANCE)
	@echo stellar bnUSD balance AM is: $(BNUSD_TOKEN_BALANCE_AM)


setupXcall:
	sh stellar.sh setupXcall
	
setup:
	sh stellar.sh setupBaln
	sh icon.sh postSetup
	sh stellar.sh mint
	sh icon.sh depositNBorrow
	sh icon.sh borrow


cross-transfer-icon-to-stellar:
	@echo ":::::::::::::BEFORE:::::::::::::::::::::"
	$(MAKE) print-balance
	@echo "transferring 1000 BnUSD from icon to stellar"
	sh icon.sh transferBnUSD
	sleep 15
	@echo ":::::::::::::AFTER:::::::::::::::::::::"
	$(MAKE) print-balance
	

cross-transfer-stellar-to-icon:
	@echo ":::::::::::::BEFORE:::::::::::::::::::::"
	$(MAKE) print-balance
	@echo "transferring 1000 BnUSD from stellar to icon"
	sh stellar.sh xTransfer
	sleep 15

	@echo ":::::::::::::AFTER:::::::::::::::::::::"
	$(MAKE) print-balance


am-deposit-withdraw-test:
	@echo ":::::::::::::BEFORE:::::::::::::::::::::"
	$(MAKE) print-balance
	@echo "Depositing 1000 BnUSD"
	sh stellar.sh depositBnUSD
	sleep 15
	@echo ":::::::::::::AFTER DEPOSIT:::::::::::::::::::::"
	$(MAKE) print-balance
	@echo "Withdrawing 100 BnUSD"
	sh icon.sh withdrawTo	
	sleep 15

	@echo ":::::::::::::AFTER:::::::::::::::::::::"
	$(MAKE) print-balance

am-deposit-withdraw-native-test:
	@echo ":::::::::::::BEFORE:::::::::::::::::::::"
	$(MAKE) print-balance
	@echo "Depositing 1000 Native tokens"
	sh stellar.sh depositNative
	sleep 15
	@echo ":::::::::::::AFTER DEPOSIT:::::::::::::::::::::"
	$(MAKE) print-balance
	@echo "Withdrawing 100 native token"
	sh icon.sh withdrawNativeTo	
	sleep 15

	@echo ":::::::::::::AFTER:::::::::::::::::::::"
	$(MAKE) print-balance


configure-stellarxcallmgr-from-icon:
	sh icon.sh configureStellarXallMgr

test-failed-refund-stellar-to-icon:
	@echo ":::::::::::::BEFORE:::::::::::::::::::::"
	$(MAKE) print-balance
	sh stellar.sh invalidXTransfer

	sleep 15
	@echo ":::::::::::::AFTER:::::::::::::::::::::"
	$(MAKE) print-balance