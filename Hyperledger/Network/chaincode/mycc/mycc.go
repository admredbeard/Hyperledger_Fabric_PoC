package main

import(
	"encoding/json"
	"fmt"
	"strings"
	"encoding/hex"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct{
	contractapi.Contract
}

type CertificateAsset struct{
	ObjectType string `json:"docType"`
	ProductID string `json:"productid"`
	PreviousProductIDs []string `json:previousids`
	Charge string `json:"charge"`
	Attributes Characteristics `json:"characteristics"`
	Composition []ChemicalComposition `json:"chemicalcomposition"`
	Properties MechanicalProperties `json:"mechanicalproperties"`
}

type CertificatePrivateDetails struct{
	ObjectType string `json:"docType"`
	ProductID string `json:"productid"`
	OrderID string `json:"orderid"`
	Initiator string `json:"initiator"`
	Customer string `json:"customer"`
	Amount int `json:"amount"`
	Timestamp string `json:"timestamp"`
}

type Characteristics struct{
	Diameter float64 `json:"diameter"`
	Length float64 `json:"length"`
	Mass float64 `json:"mass"`
}

type ChemicalComposition struct{
	Chemical string `json:"chemical"`
	Value float64 `json:"value"`
}

type MechanicalProperties struct{
	Tensile TensileStruct `json:"tensilevalues"`
	Stress StressStruct `json:"stressvalues"`
	ProofOfLoad ProofOfLoadStruct `json:"proofofloadvalues"`
	Hardness HardnessStruct `json:"hardnessvalues"`
}

type TensileStruct struct{
	TensileStrength float64 `json:"tensilestrength"`
	TensileTest Test `json:"tensiletest"`
}

type StressStruct struct{
	Stress float64 `json:"stress"`
	StressTest Test `json:"stresstest"`
}

type ProofOfLoadStruct struct{
	ProofOfLoad float64 `json:"proofofload"`
	ProofOfLoadTest Test `json:"proofofloadtest"`
}

type HardnessStruct struct{
	Hardness float64 `json:"hardness"`
	HardnessTest Test `json:"hardnesstest"`
}

type Test struct{
	Amount int `json:"#tested"`
	MinRes float64 `json:"minvalue"`
	MaxRes float64 `json:"maxvalue"`
}

type certificateTransientInput struct{
	ProductID string `json:"productid"`
	Charge string `json:"charge"`
	Characteristics Characteristics `json:"characteristics"`
	Composition []ChemicalComposition `json:"chemicalcomposition"`
	Properties MechanicalProperties `json:"mechanicalproperties"`
	OrderID string `json:"orderid"`
	Initiator string `json:"initiator"`
	Customer string `json:"customer"`
	Amount int `json:"amount"`
}

type QueryResult struct {
	Key    string `json:"Key"`
	Record *CertificateAsset
}

type HistoryResults struct{
	SameIDHistory []QueryResult `json:"sameidhistory"`
	OldIDHistory []string `json:"oldids"`
}

type InitValues struct{
	ID string `json:"id"`
	Value int `json:"value"`
}

func (s *SmartContract) Init(ctx contractapi.TransactionContextInterface) error {
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil{
		return fmt.Errorf("Error getting mspID of initiator: " + err.Error())
	}
	transaction := &InitValues{
		ID: mspID,
		Value: 100,
	}

	transactionJSONAsBytes, err := json.Marshal(transaction)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	err = ctx.GetStub().PutState(mspID, transactionJSONAsBytes)
	if err != nil{
		return fmt.Errorf("failed to put initial commit into public stateDB: %s", err.Error())
	}

	return nil
}

func (s *SmartContract) ReadInitValue(ctx contractapi.TransactionContextInterface, mspID string) (*InitValues, error){
	transactionAsBytes, err := ctx.GetStub().GetState(mspID) //get the certificate from world state
	if err != nil {
			return nil, fmt.Errorf("failed to read from world state %s", err.Error())
		}
		if transactionAsBytes == nil {
			return nil, fmt.Errorf("%s does not exist", mspID)
		}

	trans := new(InitValues)
	_ = json.Unmarshal(transactionAsBytes, trans)

	return trans, nil
}

// ===============================================
// NewCertificate - creates a new certificate with given parameters
// ===============================================
func (s *SmartContract) NewCertificate(ctx contractapi.TransactionContextInterface) error{

	_, err := ctx.GetClientIdentity().GetMSPID()

	if err != nil{
		return fmt.Errorf("Error getting mspID of Main: " + err.Error())
	}//else if mspID != "MainOrgMSP"{
	//	return fmt.Errorf("Only MainOrgMSP can create a new certificate")
	//}

	transMap, err := ctx.GetStub().GetTransient()
	if err != nil{
		return fmt.Errorf("Error getting transient data: " + err.Error())
	}

	transientCertificateJSON, ok := transMap["certificate"]
	if !ok{
		return fmt.Errorf("certificate not found in the transient map")
	}

	certificateInput := certificateTransientInput{}
	err = json.Unmarshal(transientCertificateJSON, &certificateInput)
	if err != nil{
		return fmt.Errorf("failed to unmarshal JSON: %s", err.Error())
	}

	err = CheckErrorInput(certificateInput)
	if err != nil{
		return fmt.Errorf(err.Error())
	}
	
	_, pdc, err := GetCollectionName(certificateInput.Initiator)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	certificateAsBytes, err := ctx.GetStub().GetState(certificateInput.ProductID)
	if err != nil{
		return fmt.Errorf("failed to get certificate: " + err.Error())
	}else if certificateAsBytes != nil{
		fmt.Println("This certificate already exists: " + certificateInput.ProductID)
		return fmt.Errorf("Certificate already exists use function: UpdateCertificate instead: " + certificateInput.ProductID)
	}

	tempCharacteristics := Characteristics{}
	if certificateInput.Characteristics != tempCharacteristics{
		tempCharacteristics = certificateInput.Characteristics
	}
	tempChemicalComposition := []ChemicalComposition{{"",0},}
	if certificateInput.Composition[0] != tempChemicalComposition[0]{
		tempChemicalComposition = certificateInput.Composition
	}
	tempMechanicalProperties := MechanicalProperties{}
	if certificateInput.Properties != tempMechanicalProperties{
		tempMechanicalProperties = certificateInput.Properties
	}


	certificate := &CertificateAsset{
		ObjectType: "Certificate",
		ProductID: 	certificateInput.ProductID,
		PreviousProductIDs: []string{0:""},
		Charge: 	certificateInput.Charge,
		Attributes: tempCharacteristics,
		Composition:  tempChemicalComposition,
		Properties: tempMechanicalProperties,
	}

	certificateJSONasBytes, err := json.Marshal(certificate)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	err = ctx.GetStub().PutState(certificateInput.ProductID, certificateJSONasBytes)
	if err != nil{
		return fmt.Errorf("failed to put certificate into public stateDB: %s", err.Error())
	}
	
	txTime, err := ctx.GetStub().GetTxTimestamp()
	if err != nil{
		return fmt.Errorf("Failed to get timestamp: " + err.Error())
	}

	certificatePrivateDetails := &CertificatePrivateDetails{
		ObjectType: "CertificatePrivateDetails",
		ProductID: certificateInput.ProductID,
		OrderID: certificateInput.OrderID,
		Initiator: certificateInput.Initiator,
		Customer: certificateInput.Customer,
		Amount: certificateInput.Amount,
		Timestamp: time.Unix(txTime.GetSeconds(), int64(txTime.GetNanos())).String(),
	}
	certificatePrivateDetailsAsBytes, err := json.Marshal(certificatePrivateDetails)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	err = ctx.GetStub().PutPrivateData(pdc, certificateInput.ProductID, certificatePrivateDetailsAsBytes)
	if err != nil{
		return fmt.Errorf("failed to put certificate private details into stateDB: %s", err.Error())
	}
	
	return nil
}


// ===============================================
// UpdateCertificate - Updates certificate with given parameters
// ===============================================
func (s *SmartContract) UpdateCertificate(ctx contractapi.TransactionContextInterface, certID string) error{
	
	mspID, err := ctx.GetClientIdentity().GetMSPID()

	if err != nil{
		return fmt.Errorf("Error getting mspID of Main: " + err.Error())
	}else if mspID != "MainOrgMSP"{
		return fmt.Errorf("Only MainOrgMSP can update a certificate for now")
	}

	transMap, err := ctx.GetStub().GetTransient()
	if err != nil{
		return fmt.Errorf("Error getting transient data: " + err.Error())
	}

	transientCertificateJSON, ok := transMap["certificate"]
	if !ok{
		return fmt.Errorf("certificate not found in the transient map")
	}

	certificateInput := certificateTransientInput{}
	err = json.Unmarshal(transientCertificateJSON, &certificateInput)
	if err != nil{
		return fmt.Errorf("failed to unmarshal JSON: %s", err.Error())
	}

	pdcOld, pdcNew, err := GetCollectionName(certificateInput.Initiator)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	oldPublicCertificateAsBytes, err := ctx.GetStub().GetState(certID)
	if err != nil{
		return fmt.Errorf("failed to get previous certificate from public: " + err.Error())
	}
	cert := CertificateAsset{}
	json.Unmarshal(oldPublicCertificateAsBytes, &cert)


	oldPrivatehashAsBytes, err := ctx.GetStub().GetPrivateDataHash(pdcOld, certID)
	if err != nil{
		return fmt.Errorf("failed to get previous certificate from private: " + err.Error())
	}else if oldPrivatehashAsBytes == nil{
		return fmt.Errorf("Not received this certificate before, use newCertificate instead")
	}

	/*
	oldPrivateCertificateAsBytes, err := ctx.GetStub().GetPrivateData(pdcOld, certID)
	if err != nil{
		return fmt.Errorf("failed to get previous certificate from private: " + err.Error())
	}else if oldPrivateCertificateAsBytes == nil{
		return fmt.Errorf("Not received this certificate before, use newCertificate instead")
	}
	certPrivate := CertificatePrivateDetails{}
	json.Unmarshal(oldPrivateCertificateAsBytes, &certPrivate)
	*/
	newID := cert.ProductID
	if certificateInput.ProductID != ""{
		newID = certificateInput.ProductID
	}

	newPreviousProductIDs := cert.PreviousProductIDs
	if newID != cert.ProductID{
		if cert.PreviousProductIDs[0] != ""{
			newPreviousProductIDs = append(newPreviousProductIDs, cert.ProductID)
		}else{
			newPreviousProductIDs = []string{cert.ProductID}
		}
	}

	newCharge := cert.Charge
	if certificateInput.Charge != ""{
		newCharge = certificateInput.Charge
	}
	newCharacteristics := cert.Attributes
	tempCharacteristics := Characteristics{}
	if certificateInput.Characteristics != tempCharacteristics{
		newCharacteristics = certificateInput.Characteristics
	}
	newChemicalComposition := cert.Composition
	tempChemicalComposition := ChemicalComposition{}
	if certificateInput.Composition[0] != tempChemicalComposition{
		newChemicalComposition = certificateInput.Composition
	}
	newMechanicalProperties := cert.Properties
	tempMechanicalProperties := MechanicalProperties{}
	if certificateInput.Properties != tempMechanicalProperties{
		newMechanicalProperties = certificateInput.Properties
	}

	certificateAsBytes, err := ctx.GetStub().GetPrivateData(pdcNew, newID)
	if err != nil{
		return fmt.Errorf("failed to get certificate: " + err.Error())
	}else if certificateAsBytes != nil{
		fmt.Println("This certificate already exists: " + newID)
		return fmt.Errorf("Certificate already in own private state: " + newID)
	}

	certificate := &CertificateAsset{
		ObjectType: "Certificate",
		ProductID: 	newID,
		PreviousProductIDs: newPreviousProductIDs,
		Charge: 	newCharge,
		Attributes: newCharacteristics,
		Composition:  newChemicalComposition,
		Properties: newMechanicalProperties,
	}

	certificateJSONasBytes, err := json.Marshal(certificate)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	err = ctx.GetStub().PutState(newID, certificateJSONasBytes)
	if err != nil{
		return fmt.Errorf("failed to put certificate into public stateDB: %s", err.Error())
	}

	txTime, err := ctx.GetStub().GetTxTimestamp()
	if err != nil{
		return fmt.Errorf("Failed to get timestamp: " + err.Error())
	}
	certificatePrivateDetails := &CertificatePrivateDetails{
		ObjectType: "CertificatePrivateDetails",
		ProductID: newID,
		OrderID: certificateInput.OrderID,
		Initiator: certificateInput.Initiator,
		Customer: certificateInput.Customer,
		Amount: certificateInput.Amount,
		Timestamp: time.Unix(txTime.GetSeconds(), int64(txTime.GetNanos())).String(),
	}
	certificatePrivateDetailsAsBytes, err := json.Marshal(certificatePrivateDetails)
	if err != nil{
		return fmt.Errorf(err.Error())
	}

	err = ctx.GetStub().PutPrivateData(pdcNew, newID, certificatePrivateDetailsAsBytes)
	if err != nil{
		return fmt.Errorf("failed to put certificate private details into stateDB: %s", err.Error())
	}

	return nil
}

// ===============================================
// GetCertificateHistory - gets the history for given certificateID
// ===============================================
func (s *SmartContract) GetCertificateHistory(ctx contractapi.TransactionContextInterface, certID string) (*HistoryResults, error){
	resultsIterator, err := ctx.GetStub().GetHistoryForKey(certID)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	if resultsIterator.HasNext() == false{
		return nil, fmt.Errorf("No certificate found with id: %s", certID)
	}

	results := &HistoryResults{
		SameIDHistory: []QueryResult{},
		OldIDHistory: []string{},
	}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		cert := new(CertificateAsset)
		_ = json.Unmarshal(queryResponse.Value, cert)

		queryResult := QueryResult{Key: queryResponse.TxId, Record: cert}
		results.SameIDHistory = append(results.SameIDHistory, queryResult)
	}

	certificateAsBytes, err := ctx.GetStub().GetState(certID)
	if err != nil{
		return nil, fmt.Errorf("failed to get previous certificate from public: " + err.Error())
	}
	certificate := CertificateAsset{}
	json.Unmarshal(certificateAsBytes, &certificate)

	results.OldIDHistory = certificate.PreviousProductIDs

	return results, nil
}

// ===============================================
// GetAllReceivedCertificateIDs - gets all received certificate ids for initiator
// ===============================================
func (s *SmartContract) GetAllReceivedCertificateIDs(ctx contractapi.TransactionContextInterface, overriddenOrg string) ([]string, error){
	mspID, err := ctx.GetClientIdentity().GetMSPID()

	if err != nil{
		return nil, fmt.Errorf("Error getting mspID of Main: " + err.Error())
	}else if mspID == "RawMaterialOrgMSP"{
		return nil, fmt.Errorf("RawMaterialOrg cannot receive certificates")
	}
	initiator := strings.Replace(mspID, "MSP", "", -1)
	if mspID == "MainOrgMSP"{
		initiator = overriddenOrg
	}

	pdc, _, err := GetCollectionName(initiator)
	if err != nil{
		return nil, fmt.Errorf(err.Error())
	}
	startKey := ""
	endKey := ""

	resultsIterator, err := ctx.GetStub().GetPrivateDataByRange(pdc, startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []string{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		cert := new(CertificatePrivateDetails)
		_ = json.Unmarshal(queryResponse.Value, cert)

		queryResult := cert.ProductID
		results = append(results, queryResult)
	}

	return results, nil
}

// ===============================================
// GetAllSentCertificateIDs - gets all sent certificate ids for initiator
// ===============================================
func (s *SmartContract) GetAllSentCertificateIDs(ctx contractapi.TransactionContextInterface, overriddenOrg string) ([]string, error){
	mspID, err := ctx.GetClientIdentity().GetMSPID()

	if err != nil{
		return nil, fmt.Errorf("Error getting mspID of Main: " + err.Error())
	}else if mspID == "AssemblerOrgMSP"{
		return nil, fmt.Errorf("AssemblerOrg cannot send certificates")
	}
	initiator := strings.Replace(mspID, "MSP", "", -1)

	if mspID == "MainOrgMSP"{
		initiator = overriddenOrg
	}
		
	_, pdc, err := GetCollectionName(initiator)
	if err != nil{
		return nil, fmt.Errorf(err.Error())
	}
	startKey := ""
	endKey := ""

	resultsIterator, err := ctx.GetStub().GetPrivateDataByRange(pdc, startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []string{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		cert := new(CertificatePrivateDetails)
		_ = json.Unmarshal(queryResponse.Value, cert)

		queryResult := cert.ProductID
		results = append(results, queryResult)
	}

	return results, nil
}

// ===============================================
// ReadCertificate - read a certificate from world state
// ===============================================
func (s *SmartContract) ReadCertificate(ctx contractapi.TransactionContextInterface, certificateID string) (*CertificateAsset, error) {

	certificateAsBytes, err := ctx.GetStub().GetState(certificateID) //get the certificate from world state
	if err != nil {
			return nil, fmt.Errorf("failed to read from world state %s", err.Error())
		}
		if certificateAsBytes == nil {
			return nil, fmt.Errorf("%s does not exist", certificateID)
		}

	cert := new(CertificateAsset)
	_ = json.Unmarshal(certificateAsBytes, cert)

	return cert, nil
}

// ===============================================
// ReadCertificatePrivateDetails - read a certificate private details from chaincode state
// ===============================================
func (s *SmartContract) ReadCertificatePrivateDetails(ctx contractapi.TransactionContextInterface, pdc string, certificateID string) (*CertificatePrivateDetails, error) {

	certificateDetailsJSON, err := ctx.GetStub().GetPrivateData(pdc, certificateID) //get the certificate from chaincode state
		if err != nil {
			return nil, fmt.Errorf("failed to read from certificate details %s", err.Error())
		}
		if certificateDetailsJSON == nil {
			return nil, fmt.Errorf("%s does not exist", certificateID)
		}

	certDetails := new(CertificatePrivateDetails)
	_ = json.Unmarshal(certificateDetailsJSON, certDetails)

	return certDetails, nil
}

// ===============================================
// GetCertificateHash - read the private data hash of certificate
// ===============================================
func (s *SmartContract) GetCertificateHash(ctx contractapi.TransactionContextInterface, collection string, certificateID string) (string, error){
	hashAsBytes, err := ctx.GetStub().GetPrivateDataHash(collection, certificateID)
	if err != nil{
		return "", fmt.Errorf("Failed to get public data hash for certificate: " + err.Error())
	}else if hashAsBytes == nil{
		return "", fmt.Errorf("Certificate does not exist: " + certificateID)
	}
	hashAsString := hex.EncodeToString(hashAsBytes)
	return hashAsString, nil
}

func main(){
	chaincode, err := contractapi.NewChaincode(new(SmartContract))

	if err != nil{
		fmt.Printf("Error creating private certificate chaincode: %s", err.Error())
		return
	}
	if err := chaincode.Start(); err != nil{
		fmt.Printf("Error starting private certificate chaincode: %s", err.Error())
	}
}

// ===============================================
// Helperfunctions to keep code more clean
// ===============================================

func GetCollectionName(initiator string) (string, string, error){
	
	switch initiator {
	case "RawMaterialOrg":
		return "", "collectionPrivateRawMaterialProcessor", nil 
	case "ProcessorOrg":
		return "collectionPrivateRawMaterialProcessor", "collectionPrivateProcessorProducer", nil
	case "ProducerOrg":
		return "collectionPrivateProcessorProducer",  "collectionPrivateProducerDistributor", nil
	case "DistributorOrg":
		return "collectionPrivateProducerDistributor", "collectionPrivateDistributorAssembler", nil
	case "AssemblerOrg":
		return "collectionPrivateDistributorAssembler", "", nil
	default:
		return "", "", fmt.Errorf("Initiator not found or initiator set as MainOrg")
	}
}

func CheckErrorInput(certificateInput certificateTransientInput) error {
	if len(certificateInput.ProductID) == 0{
		return fmt.Errorf("Product ID must be a non-empty string")
	}
	if len(certificateInput.Charge) == 0{
		return fmt.Errorf("Charge number must be a non-empty string")
	}
	if len(certificateInput.OrderID) == 0{
		return fmt.Errorf("Order ID must be a non-empty string")
	}
	if len(certificateInput.Initiator) == 0{
		return fmt.Errorf("Initiator must be a non-empty string")
	}
	if len(certificateInput.Customer) == 0{
		return fmt.Errorf("Customer must be a non-empty string")
	}
	if certificateInput.Amount <= 0{
		return fmt.Errorf("Amount must be a positive integer")
	}
	return nil
}