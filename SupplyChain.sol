// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SupplyChain
 * @dev Tracks product movement through the supply chain
 */
contract SupplyChain {
    
    enum Stage {
        Harvested,      
        InTransit,      
        AtWarehouse,    
        AtDistributor, 
        AtRetailer,    
        Sold            
    }
    
    struct Movement {
        Stage stage;
        address handler;        
        string handlerName;     
        string location;        
        uint256 timestamp;
        string notes;           
        int16 temperature;      
        uint16 humidity;       
    }
    
    struct Journey {
        string batchId;
        Movement[] movements;
        Stage currentStage;
        bool isComplete;
    }
    
  
    mapping(string => Journey) public journeys;
    
  
    mapping(string => bool) public journeyExists;
    
    
    event JourneyStarted(
        string indexed batchId,
        address indexed farmer,
        uint256 timestamp
    );
    
    event StageUpdated(
        string indexed batchId,
        Stage stage,
        address indexed handler,
        string location,
        uint256 timestamp
    );
    
    event JourneyCompleted(
        string indexed batchId,
        uint256 timestamp
    );
    
    
    modifier journeyMustExist(string memory _batchId) {
        require(journeyExists[_batchId], "Journey does not exist for this batch");
        _;
    }
    
    modifier journeyNotComplete(string memory _batchId) {
        require(!journeys[_batchId].isComplete, "Journey is already complete");
        _;
    }
    
    /**
     * @dev Start a journey for a product batch (called after harvest)
     */
    function startJourney(
        string memory _batchId,
        string memory _farmName,
        string memory _farmLocation,
        int16 _temperature,
        uint16 _humidity
    ) external {
        require(!journeyExists[_batchId], "Journey already exists");
        require(bytes(_batchId).length > 0, "Batch ID cannot be empty");
        
        Journey storage journey = journeys[_batchId];
        journey.batchId = _batchId;
        journey.currentStage = Stage.Harvested;
        journey.isComplete = false;
        
        Movement memory initialMovement = Movement({
            stage: Stage.Harvested,
            handler: msg.sender,
            handlerName: _farmName,
            location: _farmLocation,
            timestamp: block.timestamp,
            notes: "Product harvested",
            temperature: _temperature,
            humidity: _humidity
        });
        
        journey.movements.push(initialMovement);
        journeyExists[_batchId] = true;
        
        emit JourneyStarted(_batchId, msg.sender, block.timestamp);
        emit StageUpdated(_batchId, Stage.Harvested, msg.sender, _farmLocation, block.timestamp);
    }
    
    /**
     * @dev Update product stage in supply chain
     */
    function updateStage(
        string memory _batchId,
        Stage _newStage,
        string memory _handlerName,
        string memory _location,
        string memory _notes,
        int16 _temperature,
        uint16 _humidity
    ) external 
        journeyMustExist(_batchId)
        journeyNotComplete(_batchId)
    {
        require(_newStage > journeys[_batchId].currentStage, "Can only move forward in supply chain");
        
        Movement memory newMovement = Movement({
            stage: _newStage,
            handler: msg.sender,
            handlerName: _handlerName,
            location: _location,
            timestamp: block.timestamp,
            notes: _notes,
            temperature: _temperature,
            humidity: _humidity
        });
        
        journeys[_batchId].movements.push(newMovement);
        journeys[_batchId].currentStage = _newStage;
        
        // Mark journey as complete if sold
        if (_newStage == Stage.Sold) {
            journeys[_batchId].isComplete = true;
            emit JourneyCompleted(_batchId, block.timestamp);
        }
        
        emit StageUpdated(_batchId, _newStage, msg.sender, _location, block.timestamp);
    }
    
    /**
     * @dev Get current stage of a product
     */
    function getCurrentStage(string memory _batchId) 
        external 
        view 
        journeyMustExist(_batchId)
        returns (Stage) 
    {
        return journeys[_batchId].currentStage;
    }
    
    /**
     * @dev Get total number of movements for a batch
     */
    function getMovementCount(string memory _batchId) 
        external 
        view 
        journeyMustExist(_batchId)
        returns (uint256) 
    {
        return journeys[_batchId].movements.length;
    }
    
    /**
     * @dev Get specific movement details
     */
    function getMovement(string memory _batchId, uint256 _index) 
        external 
        view 
        journeyMustExist(_batchId)
        returns (Movement memory) 
    {
        require(_index < journeys[_batchId].movements.length, "Invalid movement index");
        return journeys[_batchId].movements[_index];
    }
    
    /**
     * @dev Get all movements for a batch
     */
    function getAllMovements(string memory _batchId) 
        external 
        view 
        journeyMustExist(_batchId)
        returns (Movement[] memory) 
    {
        return journeys[_batchId].movements;
    }
    
    /**
     * @dev Check if journey is complete
     */
    function isJourneyComplete(string memory _batchId) 
        external 
        view 
        journeyMustExist(_batchId)
        returns (bool) 
    {
        return journeys[_batchId].isComplete;
    }
    
    /**
     * @dev Get latest temperature and humidity readings
     */
    function getLatestConditions(string memory _batchId) 
        external 
        view 
        journeyMustExist(_batchId)
        returns (int16 temperature, uint16 humidity, uint256 timestamp) 
    {
        Movement[] storage movements = journeys[_batchId].movements;
        require(movements.length > 0, "No movements recorded");
        
        Movement storage latest = movements[movements.length - 1];
        return (latest.temperature, latest.humidity, latest.timestamp);
    }
}
