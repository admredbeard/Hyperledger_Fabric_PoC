import random
import string

def get_random_cert_all(update):
    
    emptyCharacteristics = False
    emptyComposition = random.choice([True, False])
    emptyProperties = random.choice([True, False])
    
    if update:
        emptyCharacteristics = random.choice([True, False])

    letter = random.choice(string.ascii_uppercase)
    charge = str(random.randint(1,1000)) + letter
    orderID = str(random.randint(1,1000)) + letter
    amount = random.randint(50,1000)
    print("Returning a certificate")
    return '\",\"charge\":\"{}\",\"previousids\":[],{}{}{}\"orderid\":\"{}\",\"amount\":{},'.format(charge, characteristics(emptyCharacteristics), composition(emptyComposition), properties(emptyProperties), orderID, amount)

def characteristics(empty):
    if empty:
        return '\"characteristics\":{},'
    dia = round(random.uniform(0.2, 15), 2)
    length = round(random.uniform(5, 25), 2)
    mass = round(random.uniform(0.1, 10), 2)
    return '\"characteristics\":{{\"diameter\":{},\"length\":{},\"mass\":{}}},'.format(dia, length, mass)

def composition(empty):
    if empty:
        return '\"chemicalcomposition\":[{\"chemical\":\"\",\"value\":0}],'
    comp = '\"chemicalcomposition\":['
    for i in range(0, random.randint(1,5)):
        if i != 0:
            comp += ','
        chemical = random.choice(string.ascii_lowercase) + str(random.randint(1,10))
        amount = round(random.uniform(0.01, 1), 2)
        comp += '{{\"chemical\":\"{}\",\"value\":{}}}'.format(chemical, amount)

    comp += '],'
    return comp

def properties(empty):
    if empty:
        return '\"mechanicalproperties\":{},' 
    return '\"mechanicalproperties\":{{{},{},{},{}}},'.format(tensile(),stress(),proofofload(),hardness())

def tensile():
    value = round(random.uniform(5,15), 2)
    tested = random.randint(2,10)
    minval = round(random.uniform(5,value), 2)
    maxval = round(random.uniform(value, 15), 2)
    return '\"tensilevalues\":{{\"tensilestrength\":{},\"tensiletest\":{{\"#tested\":{},\"minvalue\":{},\"maxvalue\":{}}}}}'.format(value,tested,minval,maxval)    

def stress():
    value = round(random.uniform(2,11), 2)
    tested = random.randint(2,10)
    minval = round(random.uniform(2,value), 2)
    maxval = round(random.uniform(value, 11), 2)
    return '\"stressvalues\":{{\"stress\":{},\"stresstest\":{{\"#tested\":{},\"minvalue\":{},\"maxvalue\":{}}}}}'.format(value,tested,minval,maxval)

def proofofload():
    value = round(random.uniform(7,13), 2)
    tested = random.randint(2,10)
    minval = round(random.uniform(7,value), 2)
    maxval = round(random.uniform(value, 13), 2)
    return '\"proofofloadvalues\":{{\"proofofload\":{},\"proofofloadtest\":{{\"#tested\":{},\"minvalue\":{},\"maxvalue\":{}}}}}'.format(value,tested,minval,maxval)    

def hardness():
    value = round(random.uniform(1,5), 2)
    tested = random.randint(2,10)
    minval = round(random.uniform(1,value), 2)
    maxval = round(random.uniform(value, 5), 2)
    return '\"hardnessvalues\":{{\"hardness\":{},\"hardnesstest\":{{\"#tested\":{},\"minvalue\":{},\"maxvalue\":{}}}}}'.format(value,tested,minval,maxval)    
