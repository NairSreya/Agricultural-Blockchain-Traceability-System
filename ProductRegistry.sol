// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProductRegistry
 * @dev Core contract for registering agricultural product batches
 */
contract ProductRegistry {
    
    struct Product {
        string batchId;           
        string productName;       
        string category;          
        string variety;           
        uint256 quantity;         
        uint256 harvestDate;      
        address farmer;           
        string farmName;          
        string farmLocation;      
        bool isActive;            
        uint256 registeredAt;     
    }
  
    mapping(string => Product) public products;
    
    mapping(string => bool) public batchExists;
    
    string[] public allBatches;
    
    mapping(address => string[]) public farmerBatches;
    
    event ProductRegistered(
        string indexed batchId,
        string productName,
        address indexed farmer,
        uint256 quantity,
        uint256 timestamp
    );
    
    event ProductDeactivated(
        string indexed batchId,
        uint256 timestamp
    );
    
    modifier onlyFarmer(string memory _batchId) {
        require(products[_batchId].farmer == msg.sender, "Only farmer can perform this action");
        _;
    }
    
    modifier batchDoesNotExist(string memory _batchId) {
        require(!batchExists[_batchId], "Batch ID already exists");
        _;
    }
    
    modifier batchMustExist(string memory _batchId) {
        require(batchExists[_batchId], "Batch ID does not exist");
        _;
    }
    
    /**
     * @dev Register a new product batch
     */
    function registerProduct(
        string memory _batchId,
        string memory _productName,
        string memory _category,
        string memory _variety,
        uint256 _quantity,
        uint256 _harvestDate,
        string memory _farmName,
        string memory _farmLocation
    ) external batchDoesNotExist(_batchId) {
        require(bytes(_batchId).length > 0, "Batch ID cannot be empty");
        require(bytes(_productName).length > 0, "Product name cannot be empty");
        require(_quantity > 0, "Quantity must be greater than 0");
        
        Product memory newProduct = Product({
            batchId: _batchId,
            productName: _productName,
            category: _category,
            variety: _variety,
            quantity: _quantity,
            harvestDate: _harvestDate,
            farmer: msg.sender,
            farmName: _farmName,
            farmLocation: _farmLocation,
            isActive: true,
            registeredAt: block.timestamp
        });
        
        products[_batchId] = newProduct;
        batchExists[_batchId] = true;
        allBatches.push(_batchId);
        farmerBatches[msg.sender].push(_batchId);
        
        emit ProductRegistered(
            _batchId,
            _productName,
            msg.sender,
            _quantity,
            block.timestamp
        );
    }
    
    /**
     * @dev Get product details by batch ID
     */
    function getProduct(string memory _batchId) 
        external 
        view 
        batchMustExist(_batchId) 
        returns (Product memory) 
    {
        return products[_batchId];
    }
    
    /**
     * @dev Get all batches registered by a farmer
     */
    function getFarmerBatches(address _farmer) 
        external 
        view 
        returns (string[] memory) 
    {
        return farmerBatches[_farmer];
    }
    
    /**
     * @dev Get total number of registered batches
     */
    function getTotalBatches() external view returns (uint256) {
        return allBatches.length;
    }
    
    /**
     * @dev Deactivate a product batch
     */
    function deactivateProduct(string memory _batchId) 
        external 
        batchMustExist(_batchId)
        onlyFarmer(_batchId)
    {
        products[_batchId].isActive = false;
        emit ProductDeactivated(_batchId, block.timestamp);
    }
    
    /**
     * @dev Check if a batch is active
     */
    function isProductActive(string memory _batchId) 
        external 
        view 
        batchMustExist(_batchId)
        returns (bool) 
    {
        return products[_batchId].isActive;
    }
}
