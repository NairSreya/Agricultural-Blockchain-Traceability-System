// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UserManagement
 * @dev Manages user roles and profiles in the agricultural supply chain
 */
contract UserManagement {
    
    enum Role {
        None,          
        Farmer,         
        Distributor,    
        Retailer,       
        Consumer        
    }
    
    struct User {
        address userAddress;
        Role role;
        string name;
        string email;
        string phone;
        string location;
        string businessLicense;  
        bool isVerified;
        bool isActive;
        uint256 registeredAt;
    }
    
    
    mapping(address => User) public users;
    
    
    mapping(address => bool) public isRegistered;
    
    
    mapping(Role => address[]) public usersByRole;
    
    
    address public admin;
    
  
    event UserRegistered(
        address indexed userAddress,
        Role role,
        string name,
        uint256 timestamp
    );
    
    event UserVerified(
        address indexed userAddress,
        uint256 timestamp
    );
    
    event UserDeactivated(
        address indexed userAddress,
        uint256 timestamp
    );
    
    event RoleUpdated(
        address indexed userAddress,
        Role oldRole,
        Role newRole,
        uint256 timestamp
    );
    
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier notRegistered() {
        require(!isRegistered[msg.sender], "User already registered");
        _;
    }
    
    modifier userExists(address _user) {
        require(isRegistered[_user], "User not registered");
        _;
    }
    
    modifier hasRole(Role _role) {
        require(users[msg.sender].role == _role, "User does not have required role");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Register a new user
     */
    function registerUser(
        Role _role,
        string memory _name,
        string memory _email,
        string memory _phone,
        string memory _location,
        string memory _businessLicense
    ) external notRegistered {
        require(_role != Role.None, "Invalid role");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        User memory newUser = User({
            userAddress: msg.sender,
            role: _role,
            name: _name,
            email: _email,
            phone: _phone,
            location: _location,
            businessLicense: _businessLicense,
            isVerified: false,
            isActive: true,
            registeredAt: block.timestamp
        });
        
        users[msg.sender] = newUser;
        isRegistered[msg.sender] = true;
        usersByRole[_role].push(msg.sender);
        
        emit UserRegistered(msg.sender, _role, _name, block.timestamp);
    }
    
    /**
     * @dev Verify a user (admin only)
     */
    function verifyUser(address _user) 
        external 
        onlyAdmin 
        userExists(_user) 
    {
        require(!users[_user].isVerified, "User already verified");
        users[_user].isVerified = true;
        emit UserVerified(_user, block.timestamp);
    }
    
    /**
     * @dev Deactivate a user (admin only)
     */
    function deactivateUser(address _user) 
        external 
        onlyAdmin 
        userExists(_user) 
    {
        require(users[_user].isActive, "User already deactivated");
        users[_user].isActive = false;
        emit UserDeactivated(_user, block.timestamp);
    }
    
    /**
     * @dev Update user role (admin only)
     */
    function updateRole(address _user, Role _newRole) 
        external 
        onlyAdmin 
        userExists(_user) 
    {
        require(_newRole != Role.None, "Invalid role");
        Role oldRole = users[_user].role;
        require(oldRole != _newRole, "Same role");
        
        users[_user].role = _newRole;
        usersByRole[_newRole].push(_user);
        
        emit RoleUpdated(_user, oldRole, _newRole, block.timestamp);
    }
    
    /**
     * @dev Get user details
     */
    function getUser(address _user) 
        external 
        view 
        userExists(_user)
        returns (User memory) 
    {
        return users[_user];
    }
    
    /**
     * @dev Get user role
     */
    function getUserRole(address _user) 
        external 
        view 
        userExists(_user)
        returns (Role) 
    {
        return users[_user].role;
    }
    
    /**
     * @dev Check if user is verified
     */
    function isUserVerified(address _user) 
        external 
        view 
        userExists(_user)
        returns (bool) 
    {
        return users[_user].isVerified;
    }
    
    /**
     * @dev Check if user is active
     */
    function isUserActive(address _user) 
        external 
        view 
        userExists(_user)
        returns (bool) 
    {
        return users[_user].isActive;
    }
    
    /**
     * @dev Get all users by role
     */
    function getUsersByRole(Role _role) 
        external 
        view 
        returns (address[] memory) 
    {
        return usersByRole[_role];
    }
    
    /**
     * @dev Get count of users by role
     */
    function getUserCountByRole(Role _role) 
        external 
        view 
        returns (uint256) 
    {
        return usersByRole[_role].length;
    }
    
    /**
     * @dev Update own profile
     */
    function updateProfile(
        string memory _name,
        string memory _email,
        string memory _phone,
        string memory _location
    ) external userExists(msg.sender) {
        users[msg.sender].name = _name;
        users[msg.sender].email = _email;
        users[msg.sender].phone = _phone;
        users[msg.sender].location = _location;
    }
    
    /**
     * @dev Transfer admin rights
     */
    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        admin = _newAdmin;
    }
}
