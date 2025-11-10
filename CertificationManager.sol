// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CertificationManager
 * @dev Manages certifications for agricultural products
 */
contract CertificationManager {
    
    enum CertificationType {
        Organic,
        FairTrade,
        NonGMO,
        USDA,
        Vegan,
        Halal,
        Kosher,
        Rainforest,
        GlobalGAP,
        Other
    }
    
    struct Certification {
        CertificationType certType;
        string certificationId;     
        string issuingAuthority;   
        uint256 issueDate;
        uint256 expiryDate;
        string documentHash;        
        bool isValid;
        address verifiedBy;        
    }
    
    mapping(string => mapping(CertificationType => Certification)) public certifications;
    
    mapping(string => CertificationType[]) public batchCertifications;
    
    mapping(address => bool) public authorizedCertifiers;
  
    address public admin;
    
    event CertificationAdded(
        string indexed batchId,
        CertificationType certType,
        string certificationId,
        address indexed addedBy,
        uint256 timestamp
    );
    
    event CertificationVerified(
        string indexed batchId,
        CertificationType certType,
        address indexed verifiedBy,
        uint256 timestamp
    );
    
    event CertificationRevoked(
        string indexed batchId,
        CertificationType certType,
        uint256 timestamp
    );
    
    event CertifierAuthorized(
        address indexed certifier,
        uint256 timestamp
    );
    
    event CertifierRevoked(
        address indexed certifier,
        uint256 timestamp
    );
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedCertifier() {
        require(authorizedCertifiers[msg.sender], "Not an authorized certifier");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        authorizedCertifiers[msg.sender] = true;
    }
    
    /**
     * @dev Add certification to a product batch
     */
    function addCertification(
        string memory _batchId,
        CertificationType _certType,
        string memory _certificationId,
        string memory _issuingAuthority,
        uint256 _issueDate,
        uint256 _expiryDate,
        string memory _documentHash
    ) external {
        require(bytes(_batchId).length > 0, "Batch ID cannot be empty");
        require(bytes(_certificationId).length > 0, "Certification ID cannot be empty");
        require(_expiryDate > _issueDate, "Expiry date must be after issue date");
        require(_expiryDate > block.timestamp, "Certification already expired");
        
        Certification memory newCert = Certification({
            certType: _certType,
            certificationId: _certificationId,
            issuingAuthority: _issuingAuthority,
            issueDate: _issueDate,
            expiryDate: _expiryDate,
            documentHash: _documentHash,
            isValid: true,
            verifiedBy: address(0)
        });
        
        certifications[_batchId][_certType] = newCert;
        batchCertifications[_batchId].push(_certType);
        
        emit CertificationAdded(
            _batchId,
            _certType,
            _certificationId,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @dev Verify a certification (authorized certifiers only)
     */
    function verifyCertification(
        string memory _batchId,
        CertificationType _certType
    ) external onlyAuthorizedCertifier {
        require(certifications[_batchId][_certType].isValid, "Certification does not exist or is invalid");
        
        certifications[_batchId][_certType].verifiedBy = msg.sender;
        
        emit CertificationVerified(_batchId, _certType, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Revoke a certification
     */
    function revokeCertification(
        string memory _batchId,
        CertificationType _certType
    ) external onlyAuthorizedCertifier {
        require(certifications[_batchId][_certType].isValid, "Certification already invalid");
        
        certifications[_batchId][_certType].isValid = false;
        
        emit CertificationRevoked(_batchId, _certType, block.timestamp);
    }
    
    /**
     * @dev Get certification details
     */
    function getCertification(
        string memory _batchId,
        CertificationType _certType
    ) external view returns (Certification memory) {
        return certifications[_batchId][_certType];
    }
    
    /**
     * @dev Get all certifications for a batch
     */
    function getAllCertifications(string memory _batchId) 
        external 
        view 
        returns (CertificationType[] memory) 
    {
        return batchCertifications[_batchId];
    }
    
    /**
     * @dev Check if certification is valid and not expired
     */
    function isCertificationValid(
        string memory _batchId,
        CertificationType _certType
    ) external view returns (bool) {
        Certification memory cert = certifications[_batchId][_certType];
        return cert.isValid && cert.expiryDate > block.timestamp;
    }
    
    /**
     * @dev Check if certification is verified
     */
    function isCertificationVerified(
        string memory _batchId,
        CertificationType _certType
    ) external view returns (bool) {
        return certifications[_batchId][_certType].verifiedBy != address(0);
    }
    
    /**
     * @dev Authorize a certifier
     */
    function authorizeCertifier(address _certifier) external onlyAdmin {
        require(_certifier != address(0), "Invalid address");
        require(!authorizedCertifiers[_certifier], "Already authorized");
        
        authorizedCertifiers[_certifier] = true;
        emit CertifierAuthorized(_certifier, block.timestamp);
    }
    
    /**
     * @dev Revoke certifier authorization
     */
    function revokeCertifier(address _certifier) external onlyAdmin {
        require(authorizedCertifiers[_certifier], "Not an authorized certifier");
        
        authorizedCertifiers[_certifier] = false;
        emit CertifierRevoked(_certifier, block.timestamp);
    }
    
    /**
     * @dev Transfer admin rights
     */
    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        admin = _newAdmin;
    }
}
