import couchdb
import json

couch = couchdb.Server()
couch.resource.credentials = ("admin", "password")

try:
    db = couch.create('certificates')
except couchdb.http.PreconditionFailed:
    db = couch['certificates']
except:
    print("Other error")

#add certificate to db
def add_certificate(cert, id):
    global db
    if id in db:
        print("Certificate already exists")
        return
    certificate = json.loads(cert)
    db[id] = certificate

#simple update of certificates existing in db
def update_certificate(cert, id, oldid):
    global db
    newid = id
    if newid in db:
        print("certificate already exists")
    if oldid not in db:
        print("Cannot update a certificate that does not exist, use add_certificate instead")
        return
    
    temp = db[oldid]
    new = json.loads(cert)
    temp['previousids'].append(oldid)
    new['previousids'] = temp['previousids']

    if new['characteristics'] == '{}':
        new['characteristics'] = temp['characteristics']

    if new['chemicalcomposition'] == []:
        new['chemicalcomposition'] = temp['chemicalcomposition']

    if new['mechanicalproperties'] == '{}':
        new['mechanicalproperties'] == temp['mechanicalproperties'] 


    db[newid] = new 

#fetch certificate data from db
def get_certificate(id):
    global db
    if id not in db:
        print("Certificate not found")
        return
    return db[id]

