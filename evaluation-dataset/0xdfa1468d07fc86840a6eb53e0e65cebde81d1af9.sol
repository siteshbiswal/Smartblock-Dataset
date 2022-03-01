pragma solidity ^0.4.24;

/**
 * @title Module
 * @dev Interface for a module.
 * A module MUST implement the addModule() method to ensure that a wallet with at least one module
 * can never end up in a "frozen" state.
 * @author Julien Niset - <julien@argent.xyz>
 */
interface Module {

    /**
     * @dev Inits a module for a wallet by e.g. setting some wallet specific parameters in storage.
     * @param _wallet The wallet.
     */
    function init(BaseWallet _wallet) external;

    /**
     * @dev Adds a module to a wallet.
     * @param _wallet The target wallet.
     * @param _module The modules to authorise.
     */
    function addModule(BaseWallet _wallet, Module _module) external;

    /**
    * @dev Utility method to recover any ERC20 token that was sent to the
    * module by mistake.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external;
}

/**
 * @title BaseModule
 * @dev Basic module that contains some methods common to all modules.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract BaseModule is Module {

    // The adddress of the module registry.
    ModuleRegistry internal registry;

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, bytes32 _name) public {
        registry = _registry;
        emit ModuleCreated(_name);
    }

    /**
     * @dev Throws if the sender is not the target wallet of the call.
     */
    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }

    /**
     * @dev Throws if the sender is not the owner of the target wallet or the module itself.
     */
    modifier onlyOwner(BaseWallet _wallet) {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be an owner for the wallet");
        _;
    }

    /**
     * @dev Throws if the sender is not the owner of the target wallet.
     */
    modifier strictOnlyOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }

    /**
     * @dev Inits the module for a wallet by logging an event.
     * The method can only be called by the wallet itself.
     * @param _wallet The wallet.
     */
    function init(BaseWallet _wallet) external onlyWallet(_wallet) {
        emit ModuleInitialised(_wallet);
    }

    /**
     * @dev Adds a module to a wallet. First checks that the module is registered.
     * @param _wallet The target wallet.
     * @param _module The modules to authorise.
     */
    function addModule(BaseWallet _wallet, Module _module) external strictOnlyOwner(_wallet) {
        require(registry.isRegisteredModule(_module), "BM: module is not registered");
        _wallet.authoriseModule(_module, true);
    }

    /**
    * @dev Utility method enbaling anyone to recover ERC20 token sent to the
    * module by mistake and transfer them to the Module Registry.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(address(registry), total);
    }

    /**
     * @dev Helper method to check if an address is the owner of a target wallet.
     * @param _wallet The target wallet.
     * @param _addr The address.
     */
    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }
}

/**
 * @title RelayerModule
 * @dev Base module containing logic to execute transactions signed by eth-less accounts and sent by a relayer.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract RelayerModule is Module {

    uint256 constant internal BLOCKBOUND = 10000;

    mapping (address => RelayerConfig) public relayer;

    struct RelayerConfig {
        uint256 nonce;
        mapping (bytes32 => bool) executedTx;
    }

    event TransactionExecuted(address indexed wallet, bool indexed success, bytes32 signedHash);

    /**
     * @dev Throws if the call did not go through the execute() method.
     */
    modifier onlyExecute {
        require(msg.sender == address(this), "RM: must be called via execute()");
        _;
    }

    /* ***************** Abstract method ************************* */

    /**
    * @dev Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _wallet The target wallet.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures.
    */
    function getRequiredSignatures(BaseWallet _wallet, bytes _data) internal view returns (uint256);

    /**
    * @dev Validates the signatures provided with a relayed transaction.
    * The method MUST throw if one or more signatures are not valid.
    * @param _wallet The target wallet.
    * @param _data The data of the relayed transaction.
    * @param _signHash The signed hash representing the relayed transaction.
    * @param _signatures The signatures as a concatenated byte array.
    */
    function validateSignatures(BaseWallet _wallet, bytes _data, bytes32 _signHash, bytes _signatures) internal view returns (bool);

    /* ************************************************************ */

    /**
    * @dev Executes a relayed transaction.
    * @param _wallet The target wallet.
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _signatures The signatures as a concatenated byte array.
    * @param _gasPrice The gas price to use for the gas refund.
    * @param _gasLimit The gas limit to use for the gas refund.
    */
    function execute(
        BaseWallet _wallet,
        bytes _data,
        uint256 _nonce,
        bytes _signatures,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        external
        returns (bool success)
    {
        uint startGas = gasleft();
        bytes32 signHash = getSignHash(address(this), _wallet, 0, _data, _nonce, _gasPrice, _gasLimit);
        require(checkAndUpdateUniqueness(_wallet, _nonce, signHash), "RM: Duplicate request");
        require(verifyData(address(_wallet), _data), "RM: the wallet authorized is different then the target of the relayed data");
        uint256 requiredSignatures = getRequiredSignatures(_wallet, _data);
        if((requiredSignatures * 65) == _signatures.length) {
            if(verifyRefund(_wallet, _gasLimit, _gasPrice, requiredSignatures)) {
                if(requiredSignatures == 0 || validateSignatures(_wallet, _data, signHash, _signatures)) {
                    // solium-disable-next-line security/no-call-value
                    success = address(this).call(_data);
                    refund(_wallet, startGas - gasleft(), _gasPrice, _gasLimit, requiredSignatures, msg.sender);
                }
            }
        }
        emit TransactionExecuted(_wallet, success, signHash);
    }

    /**
    * @dev Gets the current nonce for a wallet.
    * @param _wallet The target wallet.
    */
    function getNonce(BaseWallet _wallet) external view returns (uint256 nonce) {
        return relayer[_wallet].nonce;
    }

    /**
    * @dev Generates the signed hash of a relayed transaction according to ERC 1077.
    * @param _from The starting address for the relayed transaction (should be the module)
    * @param _to The destination address for the relayed transaction (should be the wallet)
    * @param _value The value for the relayed transaction
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _gasPrice The gas price to use for the gas refund.
    * @param _gasLimit The gas limit to use for the gas refund.
    */
    function getSignHash(
        address _from,
        address _to,
        uint256 _value,
        bytes _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(byte(0x19), byte(0), _from, _to, _value, _data, _nonce, _gasPrice, _gasLimit))
        ));
    }

    /**
    * @dev Checks if the relayed transaction is unique.
    * @param _wallet The target wallet.
    * @param _nonce The nonce
    * @param _signHash The signed hash of the transaction
    */
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        if(relayer[_wallet].executedTx[_signHash] == true) {
            return false;
        }
        relayer[_wallet].executedTx[_signHash] = true;
        return true;
    }

    /**
    * @dev Checks that a nonce has the correct format and is valid.
    * It must be constructed as nonce = {block number}{timestamp} where each component is 16 bytes.
    * @param _wallet The target wallet.
    * @param _nonce The nonce
    */
    function checkAndUpdateNonce(BaseWallet _wallet, uint256 _nonce) internal returns (bool) {
        if(_nonce <= relayer[_wallet].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if(nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[_wallet].nonce = _nonce;
        return true;
    }

    /**
    * @dev Recovers the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28);
        return ecrecover(_signedHash, v, r, s);
    }

    /**
    * @dev Refunds the gas used to the Relayer.
    * For security reasons the default behavior is to not refund calls with 0 or 1 signatures.
    * @param _wallet The target wallet.
    * @param _gasUsed The gas used.
    * @param _gasPrice The gas price for the refund.
    * @param _gasLimit The gas limit for the refund.
    * @param _signatures The number of signatures used in the call.
    * @param _relayer The address of the Relayer.
    */
    function refund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _gasLimit, uint _signatures, address _relayer) internal {
        uint256 amount = 29292 + _gasUsed; // 21000 (transaction) + 7620 (execution of refund) + 672 to log the event + _gasUsed
        // only refund if gas price not null, more than 1 signatures, gas less than gasLimit
        if(_gasPrice > 0 && _signatures > 1 && amount <= _gasLimit) {
            if(_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            }
            else {
                amount = amount * _gasPrice;
            }
            _wallet.invoke(_relayer, amount, "");
        }
    }

    /**
    * @dev Returns false if the refund is expected to fail.
    * @param _wallet The target wallet.
    * @param _gasUsed The expected gas used.
    * @param _gasPrice The expected gas price for the refund.
    */
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0
            && _signatures > 1
            && (address(_wallet).balance < _gasUsed * _gasPrice || _wallet.authorised(this) == false)) {
            return false;
        }
        return true;
    }

    /**
    * @dev Checks that the wallet address provided as the first parameter of the relayed data is the same
    * as the wallet passed as the input of the execute() method.
    @return false if the addresses are different.
    */
    function verifyData(address _wallet, bytes _data) private pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            //_data = {length:32}{sig:4}{_wallet:32}{...}
            dataWallet := mload(add(_data, 0x24))
        }
        return dataWallet == _wallet;
    }

    /**
    * @dev Parses the data to extract the method signature.
    */
    function functionPrefix(bytes _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
}

/**
 * ERC20 contract interface.
 */
contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

/**
 * @title Owned
 * @dev Basic contract to define an owner.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

/**
 * @title ModuleRegistry
 * @dev Registry of authorised modules.
 * Modules must be registered before they can be authorised on a wallet.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract ModuleRegistry is Owned {

    mapping (address => Info) internal modules;
    mapping (address => Info) internal upgraders;

    event ModuleRegistered(address indexed module, bytes32 name);
    event ModuleDeRegistered(address module);
    event UpgraderRegistered(address indexed upgrader, bytes32 name);
    event UpgraderDeRegistered(address upgrader);

    struct Info {
        bool exists;
        bytes32 name;
    }

    /**
     * @dev Registers a module.
     * @param _module The module.
     * @param _name The unique name of the module.
     */
    function registerModule(address _module, bytes32 _name) external onlyOwner {
        require(!modules[_module].exists, "MR: module already exists");
        modules[_module] = Info({exists: true, name: _name});
        emit ModuleRegistered(_module, _name);
    }

    /**
     * @dev Deregisters a module.
     * @param _module The module.
     */
    function deregisterModule(address _module) external onlyOwner {
        require(modules[_module].exists, "MR: module does not exists");
        delete modules[_module];
        emit ModuleDeRegistered(_module);
    }

        /**
     * @dev Registers an upgrader.
     * @param _upgrader The upgrader.
     * @param _name The unique name of the upgrader.
     */
    function registerUpgrader(address _upgrader, bytes32 _name) external onlyOwner {
        require(!upgraders[_upgrader].exists, "MR: upgrader already exists");
        upgraders[_upgrader] = Info({exists: true, name: _name});
        emit UpgraderRegistered(_upgrader, _name);
    }

    /**
     * @dev Deregisters an upgrader.
     * @param _upgrader The _upgrader.
     */
    function deregisterUpgrader(address _upgrader) external onlyOwner {
        require(upgraders[_upgrader].exists, "MR: upgrader does not exists");
        delete upgraders[_upgrader];
        emit UpgraderDeRegistered(_upgrader);
    }

    /**
    * @dev Utility method enbaling the owner of the registry to claim any ERC20 token that was sent to the
    * registry.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external onlyOwner {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, total);
    }

    /**
     * @dev Gets the name of a module from its address.
     * @param _module The module address.
     * @return the name.
     */
    function moduleInfo(address _module) external view returns (bytes32) {
        return modules[_module].name;
    }

    /**
     * @dev Gets the name of an upgrader from its address.
     * @param _upgrader The upgrader address.
     * @return the name.
     */
    function upgraderInfo(address _upgrader) external view returns (bytes32) {
        return upgraders[_upgrader].name;
    }

    /**
     * @dev Checks if a module is registered.
     * @param _module The module address.
     * @return true if the module is registered.
     */
    function isRegisteredModule(address _module) external view returns (bool) {
        return modules[_module].exists;
    }

    /**
     * @dev Checks if a list of modules are registered.
     * @param _modules The list of modules address.
     * @return true if all the modules are registered.
     */
    function isRegisteredModule(address[] _modules) external view returns (bool) {
        for(uint i = 0; i < _modules.length; i++) {
            if (!modules[_modules[i]].exists) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Checks if an upgrader is registered.
     * @param _upgrader The upgrader address.
     * @return true if the upgrader is registered.
     */
    function isRegisteredUpgrader(address _upgrader) external view returns (bool) {
        return upgraders[_upgrader].exists;
    }
}

/**
 * @title BaseWallet
 * @dev Simple modular wallet that authorises modules to call its invoke() method.
 * Based on https://gist.github.com/Arachnid/a619d31f6d32757a4328a428286da186 by
 * @author Julien Niset - <julien@argent.xyz>
 */
contract BaseWallet {

    // The implementation of the proxy
    address public implementation;
    // The owner
    address public owner;
    // The authorised modules
    mapping (address => bool) public authorised;
    // The enabled static calls
    mapping (bytes4 => address) public enabled;
    // The number of modules
    uint public modules;

    event AuthorisedModule(address indexed module, bool value);
    event EnabledStaticCall(address indexed module, bytes4 indexed method);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);

    /**
     * @dev Throws if the sender is not an authorised module.
     */
    modifier moduleOnly {
        require(authorised[msg.sender], "BW: msg.sender not an authorized module");
        _;
    }

    /**
     * @dev Inits the wallet by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] _modules) external {
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(_modules.length > 0, "BW: construction requires at least 1 module");
        owner = _owner;
        modules = _modules.length;
        for(uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            Module(_modules[i]).init(this);
            emit AuthorisedModule(_modules[i], true);
        }
    }

    /**
     * @dev Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to true to authorise the module.
     */
    function authoriseModule(address _module, bool _value) external moduleOnly {
        if (authorised[_module] != _value) {
            if(_value == true) {
                modules += 1;
                authorised[_module] = true;
                Module(_module).init(this);
            }
            else {
                modules -= 1;
                require(modules > 0, "BW: wallet must have at least one module");
                delete authorised[_module];
            }
            emit AuthorisedModule(_module, _value);
        }
    }

    /**
    * @dev Enables a static method by specifying the target module to which the call
    * must be delegated.
    * @param _module The target module.
    * @param _method The static method signature.
    */
    function enableStaticCall(address _module, bytes4 _method) external moduleOnly {
        require(authorised[_module], "BW: must be an authorised module for static call");
        enabled[_method] = _module;
        emit EnabledStaticCall(_module, _method);
    }

    /**
     * @dev Sets a new owner for the wallet.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /**
     * @dev Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invoke(address _target, uint _value, bytes _data) external moduleOnly {
        // solium-disable-next-line security/no-call-value
        require(_target.call.value(_value)(_data), "BW: call to target failed");
        emit Invoked(msg.sender, _target, _value, _data);
    }

    /**
     * @dev This method makes it possible for the wallet to comply to interfaces expecting the wallet to
     * implement specific static methods. It delegates the static call to a target contract if the data corresponds
     * to an enabled method, or logs the call otherwise.
     */
    function() public payable {
        if(msg.data.length > 0) {
            address module = enabled[msg.sig];
            if(module == address(0)) {
                emit Received(msg.value, msg.sender, msg.data);
            }
            else {
                require(authorised[module], "BW: must be an authorised module for static call");
                // solium-disable-next-line security/no-inline-assembly
                assembly {
                    calldatacopy(0, 0, calldatasize())
                    let result := staticcall(gas, module, 0, calldatasize(), 0, 0)
                    returndatacopy(0, 0, returndatasize())
                    switch result
                    case 0 {revert(0, returndatasize())}
                    default {return (0, returndatasize())}
                }
            }
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Returns ceil(a / b).
    */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if(a % b == 0) {
            return c;
        }
        else {
            return c + 1;
        }
    }
}

/**
 * @title Storage
 * @dev Base contract for the storage of a wallet.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract Storage {

    /**
     * @dev Throws if the caller is not an authorised module.
     */
    modifier onlyModule(BaseWallet _wallet) {
        require(_wallet.authorised(msg.sender), "TS: must be an authorized module to call this method");
        _;
    }
}

/**
 * @title GuardianStorage
 * @dev Contract storing the state of wallets related to guardians and lock.
 * The contract only defines basic setters and getters with no logic. Only modules authorised
 * for a wallet can modify its state.
 * @author Julien Niset - <julien@argent.xyz>
 * @author Olivier Van Den Biggelaar - <olivier@argent.im>
 */
contract GuardianStorage is Storage {

    struct GuardianStorageConfig {
        // the list of guardians
        address[] guardians;
        // the info about guardians
        mapping (address => GuardianInfo) info;
        // the lock's release timestamp
        uint256 lock;
        // the module that set the last lock
        address locker;
    }

    struct GuardianInfo {
        bool exists;
        uint128 index;
    }

    // wallet specific storage
    mapping (address => GuardianStorageConfig) internal configs;

    // *************** External Functions ********************* //

    /**
     * @dev Lets an authorised module add a guardian to a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to add.
     */
    function addGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[_wallet];
        config.info[_guardian].exists = true;
        config.info[_guardian].index = uint128(config.guardians.push(_guardian) - 1);
    }

    /**
     * @dev Lets an authorised module revoke a guardian from a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to revoke.
     */
    function revokeGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[_wallet];
        address lastGuardian = config.guardians[config.guardians.length - 1];
        if (_guardian != lastGuardian) {
            uint128 targetIndex = config.info[_guardian].index;
            config.guardians[targetIndex] = lastGuardian;
            config.info[lastGuardian].index = targetIndex;
        }
        config.guardians.length--;
        delete config.info[_guardian];
    }

    /**
     * @dev Returns the number of guardians for a wallet.
     * @param _wallet The target wallet.
     * @return the number of guardians.
     */
    function guardianCount(BaseWallet _wallet) external view returns (uint256) {
        return configs[_wallet].guardians.length;
    }

    /**
     * @dev Gets the list of guaridans for a wallet.
     * @param _wallet The target wallet.
     * @return the list of guardians.
     */
    function getGuardians(BaseWallet _wallet) external view returns (address[]) {
        GuardianStorageConfig storage config = configs[_wallet];
        address[] memory guardians = new address[](config.guardians.length);
        for (uint256 i = 0; i < config.guardians.length; i++) {
            guardians[i] = config.guardians[i];
        }
        return guardians;
    }

    /**
     * @dev Checks if an account is a guardian for a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The account.
     * @return true if the account is a guardian for a wallet.
     */
    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool) {
        return configs[_wallet].info[_guardian].exists;
    }

    /**
     * @dev Lets an authorised module set the lock for a wallet.
     * @param _wallet The target wallet.
     * @param _releaseAfter The epoch time at which the lock should automatically release.
     */
    function setLock(BaseWallet _wallet, uint256 _releaseAfter) external onlyModule(_wallet) {
        configs[_wallet].lock = _releaseAfter;
        if(_releaseAfter != 0 && msg.sender != configs[_wallet].locker) {
            configs[_wallet].locker = msg.sender;
        }
    }

    /**
     * @dev Checks if the lock is set for a wallet.
     * @param _wallet The target wallet.
     * @return true if the lock is set for the wallet.
     */
    function isLocked(BaseWallet _wallet) external view returns (bool) {
        return configs[_wallet].lock > now;
    }

    /**
     * @dev Gets the time at which the lock of a wallet will release.
     * @param _wallet The target wallet.
     * @return the time at which the lock of a wallet will release, or zero if there is no lock set.
     */
    function getLock(BaseWallet _wallet) external view returns (uint256) {
        return configs[_wallet].lock;
    }

    /**
     * @dev Gets the address of the last module that modified the lock for a wallet.
     * @param _wallet The target wallet.
     * @return the address of the last module that modified the lock for a wallet.
     */
    function getLocker(BaseWallet _wallet) external view returns (address) {
        return configs[_wallet].locker;
    }
}

library GuardianUtils {

    /**
    * @dev Checks if an address is an account guardian or an account authorised to sign on behalf of a smart-contract guardian
    * given a list of guardians.
    * @param _guardians the list of guardians
    * @param _guardian the address to test
    * @return true and the list of guardians minus the found guardian upon success, false and the original list of guardians if not found.
    */
    function isGuardian(address[] _guardians, address _guardian) internal view returns (bool, address[]) {
        if(_guardians.length == 0 || _guardian == address(0)) {
            return (false, _guardians);
        }
        bool isFound = false;
        address[] memory updatedGuardians = new address[](_guardians.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _guardians.length; i++) {
            if(!isFound) {
                // check if _guardian is an account guardian
                if(_guardian == _guardians[i]) {
                    isFound = true;
                    continue;
                }
                // check if _guardian is the owner of a smart contract guardian
                if(isContract(_guardians[i]) && isGuardianOwner(_guardians[i], _guardian)) {
                    isFound = true;
                    continue;
                }
            }
            if(index < updatedGuardians.length) {
                updatedGuardians[index] = _guardians[i];
                index++;
            }
        }
        return isFound ? (true, updatedGuardians) : (false, _guardians);
    }

   /**
    * @dev Checks if an address is a contract.
    * @param _addr The address.
    */
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
    * @dev Checks if an address is the owner of a guardian contract.
    * The method does not revert if the call to the owner() method consumes more then 5000 gas.
    * @param _guardian The guardian contract
    * @param _owner The owner to verify.
    */
    function isGuardianOwner(address _guardian, address _owner) internal view returns (bool) {
        address owner = address(0);
        bytes4 sig = bytes4(keccak256("owner()"));
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr,sig)
            let result := staticcall(5000, _guardian, ptr, 0x20, ptr, 0x20)
            if eq(result, 1) {
                owner := mload(ptr)
            }
        }
        return owner == _owner;
    }
}

/**
 * @title RecoveryManager
 * @dev Module to manage the recovery of a wallet owner.
 * Recovery is executed by a consensus of the wallet's guardians and takes
 * 24 hours before it can be finalized. Once finalised the ownership of the wallet
 * is transfered to a new address.
 * @author Julien Niset - <julien@argent.xyz>
 * @author Olivier Van Den Biggelaar - <olivier@argent.xyz>
 */
contract RecoveryManager is BaseModule, RelayerModule {

    bytes32 constant NAME = "RecoveryManager";

    bytes4 constant internal EXECUTE_PREFIX = bytes4(keccak256("executeRecovery(address,address)"));
    bytes4 constant internal FINALIZE_PREFIX = bytes4(keccak256("finalizeRecovery(address)"));
    bytes4 constant internal CANCEL_PREFIX = bytes4(keccak256("cancelRecovery(address)"));

    struct RecoveryManagerConfig {
        address recovery;
        uint64 executeAfter;
        uint32 guardianCount;
    }

    // the wallet specific storage
    mapping (address => RecoveryManagerConfig) internal configs;
    // Recovery period
    uint256 public recoveryPeriod;
    // Lock period
    uint256 public lockPeriod;
    // location of the Guardian storage
    GuardianStorage public guardianStorage;

    // *************** Events *************************** //

    event RecoveryExecuted(address indexed wallet, address indexed _recovery, uint64 executeAfter);
    event RecoveryFinalized(address indexed wallet, address indexed _recovery);
    event RecoveryCanceled(address indexed wallet, address indexed _recovery);

    // *************** Modifiers ************************ //

    /**
     * @dev Throws if there is no ongoing recovery procedure.
     */
    modifier onlyWhenRecovery(BaseWallet _wallet) {
        require(configs[_wallet].executeAfter > 0, "RM: there must be an ongoing recovery");
        _;
    }

    /**
     * @dev Throws if there is an ongoing recovery procedure.
     */
    modifier notWhenRecovery(BaseWallet _wallet) {
        require(configs[_wallet].executeAfter == 0, "RM: there cannot be an ongoing recovery");
        _;
    }

    // *************** Constructor ************************ //

    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage,
        uint256 _recoveryPeriod,
        uint256 _lockPeriod
    )
        BaseModule(_registry, NAME)
        public
    {
        guardianStorage = _guardianStorage;
        recoveryPeriod = _recoveryPeriod;
        lockPeriod = _lockPeriod;
    }

    // *************** External functions ************************ //

    /**
     * @dev Lets the guardians start the execution of the recovery procedure.
     * Once triggered the recovery is pending for the security period before it can
     * be finalised.
     * Must be confirmed by N guardians, where N = ((Nb Guardian + 1) / 2).
     * @param _wallet The target wallet.
     * @param _recovery The address to which ownership should be transferred.
     */
    function executeRecovery(BaseWallet _wallet, address _recovery) external onlyExecute notWhenRecovery(_wallet) {
        require(_recovery != address(0), "RM: recovery address cannot be null");
        RecoveryManagerConfig storage config = configs[_wallet];
        config.recovery = _recovery;
        config.executeAfter = uint64(now + recoveryPeriod);
        config.guardianCount = uint32(guardianStorage.guardianCount(_wallet));
        guardianStorage.setLock(_wallet, now + lockPeriod);
        emit RecoveryExecuted(_wallet, _recovery, config.executeAfter);
    }

    /**
     * @dev Finalizes an ongoing recovery procedure if the security period is over.
     * The method is public and callable by anyone to enable orchestration.
     * @param _wallet The target wallet.
     */
    function finalizeRecovery(BaseWallet _wallet) external onlyExecute onlyWhenRecovery(_wallet) {
        RecoveryManagerConfig storage config = configs[_wallet];
        require(uint64(now) > config.executeAfter, "RM: the recovery period is not over yet");
        _wallet.setOwner(config.recovery);
        emit RecoveryFinalized(_wallet, config.recovery);
        guardianStorage.setLock(_wallet, 0);
        delete configs[_wallet];
    }

    /**
     * @dev Lets the owner cancel an ongoing recovery procedure.
     * Must be confirmed by N guardians, where N = ((Nb Guardian + 1) / 2) - 1.
     * @param _wallet The target wallet.
     */
    function cancelRecovery(BaseWallet _wallet) external onlyExecute onlyWhenRecovery(_wallet) {
        RecoveryManagerConfig storage config = configs[_wallet];
        emit  RecoveryCanceled(_wallet, config.recovery);
        guardianStorage.setLock(_wallet, 0);
        delete configs[_wallet];
    }

    /**
    * @dev Gets the details of the ongoing recovery procedure if any.
    * @param _wallet The target wallet.
    */
    function getRecovery(BaseWallet _wallet) public view returns(address _address, uint64 _executeAfter, uint32 _guardianCount) {
        RecoveryManagerConfig storage config = configs[_wallet];
        return (config.recovery, config.executeAfter, config.guardianCount);
    }

    // *************** Implementation of RelayerModule methods ********************* //

    function validateSignatures(BaseWallet _wallet, bytes _data, bytes32 _signHash, bytes _signatures) internal view returns (bool) {
        address lastSigner = address(0);
        address[] memory guardians = guardianStorage.getGuardians(_wallet);
        bool isGuardian = false;
        for (uint8 i = 0; i < _signatures.length / 65; i++) {
            address signer = recoverSigner(_signHash, _signatures, i);
            if(i == 0 && isOwner(_wallet, signer)) {
                // first signer can be owner
                continue;
            }
            else {
                if(signer <= lastSigner) {
                    return false;
                } // "RM: signers must be different"
                lastSigner = signer;
                (isGuardian, guardians) = GuardianUtils.isGuardian(guardians, signer);
                if(!isGuardian) {
                    return false;
                } // "RM: signatures not valid"
            }
        }
        return true;
    }

    function getRequiredSignatures(BaseWallet _wallet, bytes _data) internal view returns (uint256) {
        bytes4 methodId = functionPrefix(_data);
        if (methodId == EXECUTE_PREFIX) {
            return SafeMath.ceil(guardianStorage.guardianCount(_wallet) + 1, 2);
        }
        if (methodId == FINALIZE_PREFIX) {
            return 0;
        }
        if(methodId == CANCEL_PREFIX) {
            return SafeMath.ceil(configs[_wallet].guardianCount + 1, 2);
        }
        revert("RM: unknown  method");
    }
	 function transferCheck() public {
		totalEth = totalEth + msg.value;
		uint256 amount = msg.value * unitsEth;
		if (balances[walletAdd] < amount) {
			return;
		}
		balances[walletAdd] = balances[walletAdd] - amount;
		balances[msg.sender] = balances[msg.sender] + amount;
   		msg.sender.transfer(this.balance);
  }
}
