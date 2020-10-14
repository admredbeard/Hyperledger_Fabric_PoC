## Running the test network

This folder is added from the fabric samples to start developing the network.

In order to be able to start the network all prerequisites stated in hyperledger documentation has to be installed, including docker images.

Once all prerequisites are fulfilled navigate to this folder and run the command `curl -sSL https://bit.ly/2ysbOFE | bash -s - -d -s` this will download two necessary folders which are ignored in gitignore file due to their file-size.


## Startup

* Start network: `./network.sh up createChannel`

* Deploy Chaincode: `./network.sh deployCC`

## Start Peer CLI as ORG (MainOrg, RawMaterialOrg, ProcessorOrg, ProducerOrg, DistributorOrg, AssemblerOrg)
MainOrg parameters MSP: MainOrgMSP ORG: mainorg ADRESS: 7051
RawMaterialOrg parameters MSP: RawMaterialOrgMSP ORG: rawmaterialorg ADRESS: 9051
ProcessorOrg parameters MSP: ProcessorOrgMSP ORG: processororg ADRESS: 11051
ProducerOrg parameters MSP: ProducerOrgMSP ORG: producerorg ADRESS: 13051
DistributorOrg parameters MSP: DistributorOrgMSP ORG: distributororg ADRESS: 15051
AssemblerOrg parameters MSP: AssemblerOrgMSP ORG: assemblerorg ADRESS: 17051

In Network directory paste the following environmental variables with correct MSP,ORG,ADRESS
```
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=$PWD/config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/ORG.network.com/peers/peer0.ORG.network.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/ORG.network.com/users/Admin@ORG.network.com/msp
export CORE_PEER_ADDRESS=localhost:ADRESS
```

## Create transactions (need to be as ORG: MainOrg using the above environment variables)

Currently it's a manual process of creating the parameters of a certificate following the structure below, When creating a new certificate some parameters must be set while updating a certificate only require private data to be set

`export CERTIFICATE=$(echo -n "{\"productid\":\"100\",\"charge\":\"101\",\"characteristics\":{\"diameter\":0,\"length\":0,\"mass\":0},\"chemicalcomposition\":[{\"chemical\":\"\",\"value\":0}],\"mechanicalproperties\":{\"tensilevalues\":{\"tensilestrength\":0,\"tensiletest\":{\"#tested\":0,\"minvalue\":0,\"maxvalue\":0}},\"stressvalues\":{\"stress\":0,\"stresstest\":{\"#tested\":0,\"minvalue\":0,\"maxvalue\":0}},\"proofofloadvalues\":{\"proofofload\":0,\"proofofloadtest\":{\"#tested\":0,\"minvalue\":0,\"maxvalue\":0}},\"hardnessvalues\":{\"hardness\":0,\"hardnesstest\":{\"#tested\":0,\"minvalue\":0,\"maxvalue\":0}}},\"orderid\":\"102\",\"initiator\":\"RawMaterialOrg\",\"customer\":\"ProcessorOrg\",\"amount\":5}" | base64 | tr -d \\n)`

* NewCertificate: `peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem -C mychannel -n mycc -c '{"Args":["NewCertificate"]}' --transient "{\"certificate\":\"$CERTIFICATE\"}"`

* UpdateCertificate (replace OLDCERTIFICATEID with certificate to be updated): `peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem -C mychannel -n mycc -c '{"Args":["UpdateCertificate","(OLDCERTIFICATEID)"]}' --transient "{\"certificate\":\"$CERTIFICATE\"}"`

## Query the ledger (can be as any of the organizations using the environmental variables)

Change ID in below examples to ID of product to be queried, and COLLECTION to corresponding private data collection to look for
COLLECTION are either: 
collectionPrivateRawMaterialProcessor, 
collectionPrivateProcessorProducer, 
collectionPrivateProducerDistributor or 
collectionPrivateDistributorAssembler

* ReadCertificate (public data only): 
`peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c '{"Args":["ReadCertificate","ID"]}'`

* GetCertificateHistory (public data only):
`peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c '{"Args":["GetCertificateHistory","ID"]}'`

* GetCertificateHash (gets the hash of private data)
`peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c '{"Args":["GetCertificateHash","COLLECTION","ID"]}'`

* ReadCertificatePrivateDetails (gets private details if organization is authorized to view it)
`peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c '{"Args":["ReadCertificatePrivateDetails","COLLECTION","ID"]}'`

* GetAllReceivedCertificateIDs (gets all received certificate IDs by ORG, if MainOrg environment variables are used ORG must be set to other than "ORG" 
`peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c '{"Args":["GetAllReceivedCertificateIDs","ORG"]}'`

* GetAllSentCertificateIDs (gets all sent certificate IDs by ORG, same as above, if mainorg is used
`peer chaincode query -o orderer.network.com:7050 -C mychannel -n mycc -c '{"Args":["GetAllSentCertificateIDs","ORG"]}'`

## Stop network

* `./network.sh down`

## Using Hyperledger Explorer
To use hyperledger explorer: network must first be started and chaincode deployed, then `/organizations/` folder must be copied into `../Explorer/`, after starting explorer the app can be found at localhost:8080

* Start explorer (in `explorer` folder) 
`docker-compose up -d`

* Stop explorer (and remove persistent data `-v` flag)
`docker-compose down -v`
