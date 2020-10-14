#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${LOWERCASE}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${LOWERCASE}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=MainOrg
LOWERCASE=mainorg
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/mainorg.network.com/tlsca/tlsca.mainorg.network.com-cert.pem
CAPEM=organizations/peerOrganizations/mainorg.network.com/ca/ca.mainorg.network.com-cert.pem

echo "$(json_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/mainorg.network.com/connection-mainorg.json
echo "$(yaml_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/mainorg.network.com/connection-mainorg.yaml

ORG=RawMaterialOrg
LOWERCASE=rawmaterialorg
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/rawmaterialorg.network.com/tlsca/tlsca.rawmaterialorg.network.com-cert.pem
CAPEM=organizations/peerOrganizations/rawmaterialorg.network.com/ca/ca.rawmaterialorg.network.com-cert.pem

echo "$(json_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/rawmaterialorg.network.com/connection-rawmaterialorg.json
echo "$(yaml_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/rawmaterialorg.network.com/connection-rawmaterialorg.yaml

ORG=ProcessorOrg
LOWERCASE=processororg
P0PORT=11051
CAPORT=9054
PEERPEM=organizations/peerOrganizations/processororg.network.com/tlsca/tlsca.processororg.network.com-cert.pem
CAPEM=organizations/peerOrganizations/processororg.network.com/ca/ca.processororg.network.com-cert.pem

echo "$(json_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/processororg.network.com/connection-processororg.json
echo "$(yaml_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/processororg.network.com/connection-processororg.yaml

ORG=ProducerOrg
LOWERCASE=producerorg
P0PORT=13051
CAPORT=10054
PEERPEM=organizations/peerOrganizations/producerorg.network.com/tlsca/tlsca.producerorg.network.com-cert.pem
CAPEM=organizations/peerOrganizations/producerorg.network.com/ca/ca.producerorg.network.com-cert.pem

echo "$(json_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/producerorg.network.com/connection-producerorg.json
echo "$(yaml_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/producerorg.network.com/connection-producerorg.yaml

ORG=DistributorOrg
LOWERCASE=distributororg
P0PORT=15051
CAPORT=11054
PEERPEM=organizations/peerOrganizations/distributororg.network.com/tlsca/tlsca.distributororg.network.com-cert.pem
CAPEM=organizations/peerOrganizations/distributororg.network.com/ca/ca.distributororg.network.com-cert.pem

echo "$(json_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/distributororg.network.com/connection-distributororg.json
echo "$(yaml_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/distributororg.network.com/connection-distributororg.yaml

ORG=AssemblerOrg
LOWERCASE=assemblerorg
P0PORT=17051
CAPORT=12054
PEERPEM=organizations/peerOrganizations/assemblerorg.network.com/tlsca/tlsca.assemblerorg.network.com-cert.pem
CAPEM=organizations/peerOrganizations/assemblerorg.network.com/ca/ca.assemblerorg.network.com-cert.pem

echo "$(json_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/assemblerorg.network.com/connection-assemblerorg.json
echo "$(yaml_ccp $ORG $LOWERCASE $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/assemblerorg.network.com/connection-assemblerorg.yaml
