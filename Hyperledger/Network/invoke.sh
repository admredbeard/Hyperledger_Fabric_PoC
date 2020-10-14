#export PATH=${PWD}/bin:$PATH
#export FABRIC_CFG_PATH=$PWD/config/
export VERBOSE=false
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem

#set +x

DELAY="0"
MAX_RETRY="3"

export CERTIFICATE=$(echo -n "$1" | base64 | tr -d \\n)
shift
PEER_CONN_PARMS=$1
shift
MODE="$1"
shift
ID="$1"
shift

chaincodeInvokeNew() {
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do  
    sleep $DELAY
    #set +x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls  $PEER_CONN_PARMS --cafile $ORDERER_CA -C 'mychannel' -n mycc -c "{\"Args\":[\"NewCertificate\"]}" --transient "{\"certificate\":\"$CERTIFICATE\"}" >&log.txt 2>&1
    res=$?
    #set +x
    test $res -eq 0 && let rc=0
    DELAY="0.5"
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Create new certificate successful ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, NewCertificate is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeInvokeUpdate(){
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do  
    sleep $DELAY
    #set -x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls $PEER_CONN_PARMS --cafile $ORDERER_CA -C 'mychannel' -n mycc -c "{\"Args\":[\"UpdateCertificate\", \"$ID\"]}" --transient "{\"certificate\":\"$CERTIFICATE\"}" >&log.txt 2>&1
    res=$?
    #set +x
    test $res -eq 0 && let rc=0
    DELAY="0.5"
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Update Ledger successful ===================== "
		echo
  else
    set -x
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Update is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeQuery(){
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do  
    sleep $DELAY
    #set -x
    peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c "{\"Args\":[\"ReadCertificate\",\"$ID\"]}" >&log.txt 2>&1
    #peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile $ORDERER_CA -C 'mychannel' -n mycc -c "{\"Args\":[\"UpdateCertificate\", \"$ID\"]}" --transient "{\"certificate\":\"$CERTIFICATE\"}" >&log.txt 2>&1
    res=$?
    #set +x
    test $res -eq 0 && let rc=0
    DELAY="0.1"
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query Ledger successful ===================== "
		echo
  else
    set -x
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

if [ "$MODE" = "Update" ] ; then
  chaincodeInvokeUpdate
elif [ "$MODE" = "Query" ] ; then
  chaincodeQuery
else
  chaincodeInvokeNew
fi