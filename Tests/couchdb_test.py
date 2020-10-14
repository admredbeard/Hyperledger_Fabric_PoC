import time
import sys
import datetime
sys.path.insert(1, '/c/Users/Daniel/Documents/EXJOBB/Exjobb_Hidden_Dreams_Daniel_Karlsson/CentralDB')

from couchdb_python import add_certificate, update_certificate, get_certificate
from random_certificate import get_random_cert_all

# Tests for the couchDB implementation on docker using functions in "couchdb_python.py" script to communicate with the db
# Random certificates can be generated instead of using the sample, by calling "get_random_cert_all()" not used in benchmarking

SAMPLE_CERTIFICATE = ('\",'
'\"charge\":\"101\",'
'\"previousids\":[],'
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
        
#Adding certificates to the db
def create_certificates(startID, amount):
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print((datetime.datetime.now() - startTime).total_seconds())
        certificateJSONString = '{\"productid\":\"' + str(id) + SAMPLE_CERTIFICATE + PDC[0]
        add_certificate(certificateJSONString, str(id))

#updating certificates that exist in the db       
def update_certificates(startID, amount, pdc, addToID, oldAddToID):
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print((datetime.datetime.now() - startTime).total_seconds())
        oldID = str(id) + oldAddToID
        newID = str(id) + addToID
        certificateJSONString = '{\"productid\":\"' + newID + SAMPLE_CERTIFICATE + pdc
        update_certificate(certificateJSONString, newID, oldID)

#fetch certificates from db
def query_certificates(startID, amount):
    id = startID
    startTime = datetime.datetime.now()
    while id < amount+startID:
        id += 1
        if id % 50 == 0:
            print("{:.1f}".format((datetime.datetime.now() - startTime).total_seconds()))
        get_certificate(str(id))


#creating and updating certificates as a whole lifecycle
def full_simulation_test(startNumber, amount):
    create_certificates(startNumber, amount)
    update_certificates(startNumber, amount, PDC[1], "A", "")
    update_certificates(startNumber, amount, PDC[2], "B", "A")
    update_certificates(startNumber, amount, PDC[3], "C", "B")
   
#Tests performed on the couchDB implementation
if __name__ == "__main__":
    #full_simulation_test(100, 5)
    #query_certificates(1050, 1051, 10)
    #create_certificates(0,1000)
    #update_certificates(1000,1000, PDC[1], "A", "")
    query_certificates(0,1000)
    