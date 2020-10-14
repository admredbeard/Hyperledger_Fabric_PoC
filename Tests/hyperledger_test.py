import os
import subprocess
import random
import datetime
from random_certificate import get_random_cert_all
from multiprocessing import Process

# Tests for docker deployed hyperledger fabric network, using subcommands to execute the bash script "invoke.sh"
# Random certificates can be generated instead of using the sample, by calling "get_random_cert_all()" not used in benchmarking
wd = os.path.abspath('..')

PATH_TO_NETWORK = "../Hyperledger/Network/"

PEER_ADDRESSES = '--peerAddresses localhost:7051 --tlsRootCertFiles ' + wd + '/Hyperledger/Network/organizations/peerOrganizations/mainorg.network.com/peers/peer0.mainorg.network.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ' + wd + '/Hyperledger/Network/organizations/peerOrganizations/rawmaterialorg.network.com/peers/peer0.rawmaterialorg.network.com/tls/ca.crt --peerAddresses localhost:11051 --tlsRootCertFiles ' + wd + '/Hyperledger/Network/organizations/peerOrganizations/processororg.network.com/peers/peer0.processororg.network.com/tls/ca.crt --peerAddresses localhost:13051 --tlsRootCertFiles ' + wd + '/Hyperledger/Network/organizations/peerOrganizations/producerorg.network.com/peers/peer0.producerorg.network.com/tls/ca.crt --peerAddresses localhost:15051 --tlsRootCertFiles ' + wd + '/Hyperledger/Network/organizations/peerOrganizations/distributororg.network.com/peers/peer0.distributororg.network.com/tls/ca.crt --peerAddresses localhost:17051 --tlsRootCertFiles ' + wd + '/Hyperledger/Network/organizations/peerOrganizations/assemblerorg.network.com/peers/peer0.assemblerorg.network.com/tls/ca.crt'

SAMPLE_CERTIFICATE = ('\",'
'\"charge\":\"101\",'
'\"characteristics\":{'
    '\"diameter\":5,'
    '\"length\":10,'
    '\"mass\":5},'
'\"chemicalcomposition\":['
    '{\"chemical\":\"c1\",'
        '\"value\":0.52},'
    '{\"chemical\":\"c2\",'
        '\"value\":0.23},'
    '{\"chemical\":\"c3\",'
        '\"value\":0.34}],'
'\"mechanicalproperties\":{'
    '\"tensilevalues\":{'
        '\"tensilestrength\":10,'
        '\"tensiletest\":{'
            '\"#tested\":5,'
            '\"minvalue\":9,'
            '\"maxvalue\":11}},'
    '\"stressvalues\":{'
        '\"stress\":5,'
        '\"stresstest\":{'
            '\"#tested\":5,'
            '\"minvalue\":3,'
            '\"maxvalue\":6}},'
    '\"proofofloadvalues\":{'
        '\"proofofload\":10,'
        '\"proofofloadtest\":{'
            '\"#tested\":5,'
            '\"minvalue\":8,'
            '\"maxvalue\":12}},'
    '\"hardnessvalues\":{'
        '\"hardness\":12,'
        '\"hardnesstest\":{'
            '\"#tested\":5,'
            '\"minvalue\":11,'
            '\"maxvalue\":12}}},'
'\"orderid\":\"103\",'
'\"amount\":100,')

PDC = ['\"initiator\":\"RawMaterialOrg\",\"customer\":\"ProcessorOrg\"}', '\"initiator\":\"ProcessorOrg\",\"customer\":\"ProducerOrg\"}', '\"initiator\":\"ProducerOrg\",\"customer\":\"DistributorOrg\"}','\"initiator\":\"DistributorOrg\",\"customer\":\"AssemblerOrg\"}']

#Creating certificates

def create_certificates4(startID, amount):
    my_env = get_env_vars("DistributorOrgMSP")
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("4 : {:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        certificateJSONString = '{\"productid\":\"' + str(id) + SAMPLE_CERTIFICATE + PDC[3]
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)


def create_certificates3(startID, amount):
    my_env = get_env_vars("ProcessorOrgMSP")
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("3 : {:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        certificateJSONString = '{\"productid\":\"' + str(id) + SAMPLE_CERTIFICATE + PDC[1]
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)


def create_certificates2(startID, amount):
    my_env = get_env_vars("RawMaterialOrgMSP")
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("2 : {:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        certificateJSONString = '{\"productid\":\"' + str(id) + SAMPLE_CERTIFICATE + PDC[0]
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)


def create_certificates(startID, amount):
    my_env = get_env_vars("MainOrgMSP")
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("1 : {:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        certificateJSONString = '{\"productid\":\"' + str(id) + get_random_cert_all(False) + PDC[0]
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES], cwd=PATH_TO_NETWORK, env=my_env)

#Creating a certificate and updating it as if it came from respective organization, --waitForEvent flag required amount < 100 is recommended
def create_and_update(startID, amount):
    my_env = get_env_vars("MainOrgMSP")
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("{:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        certificateJSONString = '{\"productid\":\"' + str(id) + SAMPLE_CERTIFICATE + PDC[0]
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)

        oldID = str(id)
        pdcIndex = 0
        for i in ["A", "B", "C"]:
            newID = str(id) + i
            pdcIndex += 1
            certificateJSONString = '{\"productid\":\"' + newID + SAMPLE_CERTIFICATE + PDC[pdcIndex]
            subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES, "Update", oldID], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)
            oldID = newID 

#unused forgot the batch setting in configtx, blocks are created every 2s thereby transactions being commited first by that time
def create_and_query(startID, amount):
    my_env = get_env_vars("MainOrgMSP")
    id = startID
    totalTime = 0
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print(totalTime)
        certificateJSONString = '{\"productid\":\"' + str(id) + SAMPLE_CERTIFICATE + PDC[0]
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)

        startTime = datetime.datetime.now()

        subprocess.run(["bash", "invoke.sh", "_", "_", "Query", str(id)], cwd = PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)

        totalTime += (datetime.datetime.now() - startTime).total_seconds()


#Update certificates, if done at same time as creating the certificate, the invoke script might need tuning to add --waitForEvent flag to make sure the certificate is on the ledger before invoking update.
def update_certificates(startID, amount, pdc, addToID, oldAddToID):
    my_env = get_env_vars("MainOrgMSP")
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("{:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        oldID = str(id) + oldAddToID
        newID = str(id) + addToID
        certificateJSONString = '{\"productid\":\"' + newID + SAMPLE_CERTIFICATE + pdc
        subprocess.run(["bash", "invoke.sh", certificateJSONString, PEER_ADDRESSES, "Update", oldID], cwd=PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)

#Get certificates, same as with update, if done together with create certificates or update certificates, --waitForEvent flag is required.
def query_certificates(startID, endID, times, asORG):
    my_env = get_env_vars(asORG)
    id = startID
    startTime = datetime.datetime.now()
    while id < times+startID:
        id += 1
        if id % 50 == 0:
            print("{:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        subprocess.run(["bash", "invoke.sh", "_", "_", "Query", str(id)], cwd = PATH_TO_NETWORK, env=my_env, stdout=subprocess.DEVNULL)

#Environmental variables for different organizations
def get_env_vars(org):
    my_env = os.environ
    my_env["PATH"]="./bin:$PATH" + my_env["PATH"]
    my_env["FABRIC_CFG_PATH"]="./config/"
    my_env["CORE_PEER_TLS_ENABLED"]="true"
    my_env["CORE_PEER_LOCALMSPID"]=org
    if org == "MainOrgMSP":
        my_env["CORE_PEER_TLS_ROOTCERT_FILE"]="../organizations/peerOrganizations/mainorg.network.com/peers/peer0.mainorg.network.com/tls/ca.crt"
        my_env["CORE_PEER_MSPCONFIGPATH"]="../organizations/peerOrganizations/mainorg.network.com/users/Admin@mainorg.network.com/msp"
        my_env["CORE_PEER_ADDRESS"]="localhost:7051"
    elif org == "RawMaterialOrgMSP":
        my_env["CORE_PEER_TLS_ROOTCERT_FILE"]="../organizations/peerOrganizations/rawmaterialorg.network.com/peers/peer0.rawmaterialorg.network.com/tls/ca.crt"
        my_env["CORE_PEER_MSPCONFIGPATH"]="../organizations/peerOrganizations/rawmaterialorg.network.com/users/Admin@rawmaterialorg.network.com/msp"
        my_env["CORE_PEER_ADDRESS"]="localhost:9051"
    elif org == "ProcessorOrgMSP":
        my_env["CORE_PEER_TLS_ROOTCERT_FILE"]="../organizations/peerOrganizations/processororg.network.com/peers/peer0.processororg.network.com/tls/ca.crt"
        my_env["CORE_PEER_MSPCONFIGPATH"]="../organizations/peerOrganizations/processororg.network.com/users/Admin@processororg.network.com/msp"
        my_env["CORE_PEER_ADDRESS"]="localhost:11051"
    elif org == "ProducerOrgMSP":
        my_env["CORE_PEER_TLS_ROOTCERT_FILE"]="../organizations/peerOrganizations/producerorg.network.com/peers/peer0.producerorg.network.com/tls/ca.crt"
        my_env["CORE_PEER_MSPCONFIGPATH"]="../organizations/peerOrganizations/producerorg.network.com/users/Admin@producerorg.network.com/msp"
        my_env["CORE_PEER_ADDRESS"]="localhost:13051"
    elif org == "DistributorOrgMSP":
        my_env["CORE_PEER_TLS_ROOTCERT_FILE"]="../organizations/peerOrganizations/distributororg.network.com/peers/peer0.distributororg.network.com/tls/ca.crt"
        my_env["CORE_PEER_MSPCONFIGPATH"]="../organizations/peerOrganizations/distributororg.network.com/users/Admin@distributororg.network.com/msp"
        my_env["CORE_PEER_ADDRESS"]="localhost:15051"
    elif org == "AssemblerOrgMSP":
        my_env["CORE_PEER_TLS_ROOTCERT_FILE"]="../organizations/peerOrganizations/assemblerorg.network.com/peers/peer0.assemblerorg.network.com/tls/ca.crt"
        my_env["CORE_PEER_MSPCONFIGPATH"]="../organizations/peerOrganizations/assemblerorg.network.com/users/Admin@assemblerorg.network.com/msp"
        my_env["CORE_PEER_ADDRESS"]="localhost:17051"
    else:
        print("INVALID ORGANIZATION FOR ENVIRONMENT VARIABLES")

    return my_env


# No need for --waitForEvent flag as long as amount > 20
def full_simulation_test(amount):
    create_certificates(3205, amount)
    update_certificates(3205, amount, PDC[1], "A", "")
    update_certificates(3205, amount, PDC[2], "B", "A")
    update_certificates(3205, amount, PDC[3], "C", "B")


#All timed tests done. uncomment to test, update certificate can only be done on existing certificates for example, output will otherwise show that it does not exist. 
if __name__ == "__main__":
    #p1 = Process(target=create_certificates, args=(10500,250,))
    #p1.start()
    #print("P1 started")
    #p2 = Process(target=create_certificates2, args=(11500,250,))
    #p2.start()
    #print("P2 started")
    #p3 = Process(target=create_certificates3, args=(12500,250,))
    #p3.start()
    #print("P3 started")
    #p4 = Process(target=create_certificates4, args=(13500,250,))
    #p4.start()
    #print("P4 started")
    
    #full_simulation_test(1)
    create_certificates(0, 1000)
    #create_and_update(3250, 10)
    #create_and_query(4700,100)
    #query_certificates(2200, 3200, 1000, "MainOrgMSP")
    #update_certificates(2000, 1000, PDC[1], "A", "")
