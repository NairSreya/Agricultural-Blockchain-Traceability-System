// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QualityControl
 * @dev Records quality checks and IoT sensor data for products
 */
contract QualityControl {
    
    enum QualityStatus {
        Excellent,
        Good,
        Fair,
        Poor,
        Rejected
    }
    
    struct QualityCheck {
        address inspector;
        string inspectorName;
        QualityStatus status;
        uint256 timestamp;
        string notes;
        string[] images;        
        bool passed;
    }
    
    struct IoTReading {
        int16 temperature;      
        uint16 humidity;      
        uint16 lightLevel;      
        uint256 timestamp;
        string sensorId;
        string location;
    }
    
    mapping(string => QualityCheck[]) public qualityChecks;
    
    mapping(string => IoTReading[]) public iotReadings;
    
    mapping(address => bool) public authorizedInspectors;
    
    mapping(address => bool) public authorizedSensors;
    
    address public admin;
    
    event QualityCheckAdded(
        string indexed batchId,
        address indexed inspector,
        QualityStatus status,
        bool passed,
        uint256 timestamp
    );
    
    event IoTReadingAdded(
        string indexed batchId,
        string sensorId,
        int16 temperature,
        uint16 humidity,
        uint256 timestamp
    );
    
    event InspectorAuthorized(address indexed inspector);
    event InspectorRevoked(address indexed inspector);
    event SensorAuthorized(address indexed sensor);
    event SensorRevoked(address indexed sensor);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedInspector() {
        require(authorizedInspectors[msg.sender], "Not an authorized inspector");
        _;
    }
    
    modifier onlyAuthorizedSensor() {
        require(authorizedSensors[msg.sender], "Not an authorized sensor");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        authorizedInspectors[msg.sender] = true;
    }
    
    /**
     * @dev Add a quality check
     */
    function addQualityCheck(
        string memory _batchId,
        string memory _inspectorName,
        QualityStatus _status,
        string memory _notes,
        string[] memory _images,
        bool _passed
    ) external onlyAuthorizedInspector {
        require(bytes(_batchId).length > 0, "Batch ID cannot be empty");
        
        QualityCheck memory newCheck = QualityCheck({
            inspector: msg.sender,
            inspectorName: _inspectorName,
            status: _status,
            timestamp: block.timestamp,
            notes: _notes,
            images: _images,
            passed: _passed
        });
        
        qualityChecks[_batchId].push(newCheck);
        
        emit QualityCheckAdded(
            _batchId,
            msg.sender,
            _status,
            _passed,
            block.timestamp
        );
    }
    
    /**
     * @dev Add IoT sensor reading
     */
    function addIoTReading(
        string memory _batchId,
        int16 _temperature,
        uint16 _humidity,
        uint16 _lightLevel,
        string memory _sensorId,
        string memory _location
    ) external onlyAuthorizedSensor {
        require(bytes(_batchId).length > 0, "Batch ID cannot be empty");
        
        IoTReading memory newReading = IoTReading({
            temperature: _temperature,
            humidity: _humidity,
            lightLevel: _lightLevel,
            timestamp: block.timestamp,
            sensorId: _sensorId,
            location: _location
        });
        
        iotReadings[_batchId].push(newReading);
        
        emit IoTReadingAdded(
            _batchId,
            _sensorId,
            _temperature,
            _humidity,
            block.timestamp
        );
    }
    
    /**
     * @dev Add multiple IoT readings in batch
     */
    function addBatchIoTReadings(
        string memory _batchId,
        int16[] memory _temperatures,
        uint16[] memory _humidities,
        uint16[] memory _lightLevels,
        string memory _sensorId,
        string memory _location
    ) external onlyAuthorizedSensor {
        require(_temperatures.length == _humidities.length, "Array lengths must match");
        require(_temperatures.length == _lightLevels.length, "Array lengths must match");
        
        for (uint256 i = 0; i < _temperatures.length; i++) {
            IoTReading memory newReading = IoTReading({
                temperature: _temperatures[i],
                humidity: _humidities[i],
                lightLevel: _lightLevels[i],
                timestamp: block.timestamp,
                sensorId: _sensorId,
                location: _location
            });
            
            iotReadings[_batchId].push(newReading);
        }
        
        emit IoTReadingAdded(
            _batchId,
            _sensorId,
            _temperatures[_temperatures.length - 1],
            _humidities[_humidities.length - 1],
            block.timestamp
        );
    }
    
    /**
     * @dev Get all quality checks for a batch
     */
    function getQualityChecks(string memory _batchId) 
        external 
        view 
        returns (QualityCheck[] memory) 
    {
        return qualityChecks[_batchId];
    }
    
    /**
     * @dev Get quality check count
     */
    function getQualityCheckCount(string memory _batchId) 
        external 
        view 
        returns (uint256) 
    {
        return qualityChecks[_batchId].length;
    }
    
    /**
     * @dev Get specific quality check
     */
    function getQualityCheck(string memory _batchId, uint256 _index) 
        external 
        view 
        returns (QualityCheck memory) 
    {
        require(_index < qualityChecks[_batchId].length, "Invalid index");
        return qualityChecks[_batchId][_index];
    }
    
    /**
     * @dev Get all IoT readings for a batch
     */
    function getIoTReadings(string memory _batchId) 
        external 
        view 
        returns (IoTReading[] memory) 
    {
        return iotReadings[_batchId];
    }
    
    /**
     * @dev Get IoT reading count
     */
    function getIoTReadingCount(string memory _batchId) 
        external 
        view 
        returns (uint256) 
    {
        return iotReadings[_batchId].length;
    }
    
    /**
     * @dev Get latest IoT reading
     */
    function getLatestIoTReading(string memory _batchId) 
        external 
        view 
        returns (IoTReading memory) 
    {
        require(iotReadings[_batchId].length > 0, "No IoT readings available");
        return iotReadings[_batchId][iotReadings[_batchId].length - 1];
    }
    
    /**
     * @dev Get average temperature for a batch
     */
    function getAverageTemperature(string memory _batchId) 
        external 
        view 
        returns (int256) 
    {
        IoTReading[] memory readings = iotReadings[_batchId];
        require(readings.length > 0, "No IoT readings available");
        
        int256 sum = 0;
        for (uint256 i = 0; i < readings.length; i++) {
            sum += readings[i].temperature;
        }
        return sum / int256(readings.length);
    }
    
    /**
     * @dev Check if all quality checks passed
     */
    function allQualityChecksPassed(string memory _batchId) 
        external 
        view 
        returns (bool) 
    {
        QualityCheck[] memory checks = qualityChecks[_batchId];
        if (checks.length == 0) return false;
        
        for (uint256 i = 0; i < checks.length; i++) {
            if (!checks[i].passed) return false;
        }
        return true;
    }
    
    /**
     * @dev Authorize quality inspector
     */
    function authorizeInspector(address _inspector) external onlyAdmin {
        require(!authorizedInspectors[_inspector], "Already authorized");
        authorizedInspectors[_inspector] = true;
        emit InspectorAuthorized(_inspector);
    }
    
    /**
     * @dev Revoke inspector authorization
     */
    function revokeInspector(address _inspector) external onlyAdmin {
        require(authorizedInspectors[_inspector], "Not authorized");
        authorizedInspectors[_inspector] = false;
        emit InspectorRevoked(_inspector);
    }
    
    /**
     * @dev Authorize IoT sensor
     */
    function authorizeSensor(address _sensor) external onlyAdmin {
        require(!authorizedSensors[_sensor], "Already authorized");
        authorizedSensors[_sensor] = true;
        emit SensorAuthorized(_sensor);
    }
    
    /**
     * @dev Revoke sensor authorization
     */
    function revokeSensor(address _sensor) external onlyAdmin {
        require(authorizedSensors[_sensor], "Not authorized");
        authorizedSensors[_sensor] = false;
        emit SensorRevoked(_sensor);
    }
}
