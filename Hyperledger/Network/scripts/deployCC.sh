
CHANNEL_NAME="$1"
CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

FABRIC_CFG_PATH=$PWD/config/

POLICY="\"OR('MainOrgMSP.member','RawMaterialOrgMSP.member','ProcessorOrgMSP.member','ProducerOrgMSP.member','DistributorOrgMSP.member','AssemblerOrgMSP.member')\""
#POLICY="AND('MainOrgMSP.member',OR('RawMaterialOrgMSP.member','ProcessorOrgMSP.member','ProducerOrgMSP.member','DistributorOrgMSP.member','AssemblerOrgMSP.member'))"

if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang" ] ; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH="./chaincode/mycc/"

	echo Vendoring Go dependencies ...
	pushd ./chaincode/mycc
	GO111MODULE=on go mod vendor
	popd
	echo Finished vendoring Go dependencies

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH="../chaincode/fabcar/javascript/"

elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
	CC_RUNTIME_LANGUAGE=java
	CC_SRC_PATH="../chaincode/fabcar/java/build/install/fabcar"

	echo Compiling Java code ...
	pushd ../chaincode/fabcar/java
	./gradlew installDist
	popd
	echo Finished compiling Java code

elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH="../chaincode/fabcar/typescript/"

	echo Compiling TypeScript code into JavaScript ...
	pushd ../chaincode/fabcar/typescript
	npm install
	npm run build
	popd
	echo Finished compiling TypeScript code into JavaScript

else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, java, javascript, and typescript
	exit 1
fi

# import utils
. scripts/envVar.sh


packageChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode package mycc.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label mycc_${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode packaging on peer0.${ORG} has failed"
  echo "===================== Chaincode is packaged on peer0.${ORG} ===================== "
  echo
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode install mycc.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.${ORG} has failed"
  echo "===================== Chaincode is installed on peer0.${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
	PACKAGE_ID=$(sed -n "/mycc_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.${ORG} has failed"
  echo "===================== Query installed successful on peer0.${ORG} on channel ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name mycc --version ${VERSION} --collections-config ./chaincode/collections_config.json --signature-policy "OR('MainOrgMSP.member','RawMaterialOrgMSP.member','ProcessorOrgMSP.member','ProducerOrgMSP.member','DistributorOrgMSP.member','AssemblerOrgMSP.member')" --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION} >&log.txt
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  echo "===================== Checking the commit readiness of the chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name mycc --version ${VERSION} --collections-config ./chaincode/collections_config.json --signature-policy "OR('MainOrgMSP.member','RawMaterialOrgMSP.member','ProcessorOrgMSP.member','ProducerOrgMSP.member','DistributorOrgMSP.member','AssemblerOrgMSP.member')" --sequence ${VERSION} --output json --init-required >&log.txt
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on peer0.${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  setGlobals 1

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name mycc $PEER_CONN_PARMS --version ${VERSION} --collections-config ./chaincode/collections_config.json --signature-policy "OR('MainOrgMSP.member','RawMaterialOrgMSP.member','ProcessorOrgMSP.member','ProducerOrgMSP.member','DistributorOrgMSP.member','AssemblerOrgMSP.member')" --sequence ${VERSION} --init-required >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

#--signature-policy "OR('MainOrgMSP.member','RawMaterialOrgMSP','ProcessorOrgMSP','ProducerOrgMSP','DistributorOrgMSP','AssemblerOrgMSP')"

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name mycc >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0.${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  setGlobals 1
  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc $PEER_CONN_PARMS --isInit -c '{"function":"Init","Args":[]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  echo "===================== Querying on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["queryAllCars"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0.${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

## at first we package the chaincode
packageChaincode 1

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on peer0.mainorg..."
installChaincode 1
echo "Install chaincode on peer0.rawmaterialorg..."
installChaincode 2
echo "Install chaincode on peer0.processororg..."
installChaincode 3
echo "Install chaincode on peer0.producerorg..."
installChaincode 4
echo "Install chaincode on peer0.distributororg..."
installChaincode 5
echo "Install chaincode on peer0.assemblerorg..."
installChaincode 6

## query whether the chaincode is installed
queryInstalled 1

## approve the definition for org1
approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
## expect org1 to have approved and org2 not to
checkCommitReadiness 1 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": false" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 2 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": false" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 3 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": false" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 4 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": false" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 5 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": false" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 6 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": false" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"

## now approve also for org2
approveForMyOrg 2

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 2 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 3 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 4 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 5 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 6 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": false" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"

## now approve also for org2
approveForMyOrg 3

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 2 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 3 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 4 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 5 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 6 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": false" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"

## now approve also for org2
approveForMyOrg 4

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 2 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 3 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 4 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 5 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 6 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": false" "\"AssemblerOrgMSP\": false"

## now approve also for org2
approveForMyOrg 5

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 2 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 3 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 4 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 5 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": false"
checkCommitReadiness 6 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": false"

## now approve also for org2
approveForMyOrg 6

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": true"
checkCommitReadiness 2 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": true"
checkCommitReadiness 3 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": true"
checkCommitReadiness 4 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": true"
checkCommitReadiness 5 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": true"
checkCommitReadiness 6 "\"MainOrgMSP\": true" "\"RawMaterialOrgMSP\": true" "\"ProcessorOrgMSP\": true" "\"ProducerOrgMSP\": true" "\"DistributorOrgMSP\": true" "\"AssemblerOrgMSP\": true"

## now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 1 2 3 4 5 6

## query on both orgs to see that the definition committed successfully
queryCommitted 1
queryCommitted 2
queryCommitted 3
queryCommitted 4
queryCommitted 5
queryCommitted 6

## Invoke the chaincode
chaincodeInvokeInit 1 2 3 4 5 6

sleep 10

# Query chaincode on peer0.org1
#echo "Querying chaincode on peer0.org1..."
#chaincodeQuery 1

exit 0
