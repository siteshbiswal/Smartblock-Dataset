pragma solidity 0.4.24;

// File: @tokenfoundry/sale-contracts/contracts/interfaces/VaultI.sol

interface VaultI {
    function deposit(address contributor) external payable;
    function saleSuccessful() external;
    function enableRefunds() external;
    function refund(address contributor) external;
    function close() external;
    function sendFundsToWallet() external;
}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: @tokenfoundry/sale-contracts/contracts/Vault.sol

// Adapted from Open Zeppelin's RefundVault

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract Vault is VaultI, Ownable {
    using SafeMath for uint256;

    enum State { Active, Success, Refunding, Closed }

    // The timestamp of the first deposit
    uint256 public firstDepositTimestamp;

    mapping (address => uint256) public deposited;

    // The amount to be disbursed to the wallet every month
    uint256 public disbursementWei;
    uint256 public disbursementDuration;

    // Wallet from the project team
    address public trustedWallet;

    // The eth amount the team will get initially if the sale is successful
    uint256 public initialWei;

    // Timestamp that has to pass before sending funds to the wallet
    uint256 public nextDisbursement;

    // Total amount that was deposited
    uint256 public totalDeposited;

    // Amount that can be refunded
    uint256 public refundable;

    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed contributor, uint256 amount);

    modifier atState(State _state) {
        require(state == _state, "This function cannot be called in the current vault state.");
        _;
    }

    constructor (
        address _wallet,
        uint256 _initialWei,
        uint256 _disbursementWei,
        uint256 _disbursementDuration
    )
        public
    {
        require(_wallet != address(0), "Wallet address should not be 0.");
        require(_disbursementWei != 0, "Disbursement Wei should be greater than 0.");
        trustedWallet = _wallet;
        initialWei = _initialWei;
        disbursementWei = _disbursementWei;
        disbursementDuration = _disbursementDuration;
        state = State.Active;
    }

    /// @dev Called by the sale contract to deposit ether for a contributor.
    function deposit(address _contributor) onlyOwner external payable {
        require(state == State.Active || state == State.Success , "Vault state must be Active or Success.");
        if (firstDepositTimestamp == 0) {
            firstDepositTimestamp = now;
        }
        totalDeposited = totalDeposited.add(msg.value);
        deposited[_contributor] = deposited[_contributor].add(msg.value);
    }

    /// @dev Sends initial funds to the wallet.
    function saleSuccessful()
        onlyOwner
        external
        atState(State.Active)
    {
        state = State.Success;
        transferToWallet(initialWei);
    }

    /// @dev Called by the owner if the project didn't deliver the testnet contracts or if we need to stop disbursements for any reasone.
    function enableRefunds() onlyOwner external {
        require(state != State.Refunding, "Vault state is not Refunding");
        state = State.Refunding;
        uint256 currentBalance = address(this).balance;
        refundable = currentBalance <= totalDeposited ? currentBalance : totalDeposited;
        emit RefundsEnabled();
    }

    /// @dev Refunds ether to the contributors if in the Refunding state.
    function refund(address _contributor) external atState(State.Refunding) {
        require(deposited[_contributor] > 0, "Refund not allowed if contributor deposit is 0.");
        uint256 refundAmount = deposited[_contributor].mul(refundable).div(totalDeposited);
        deposited[_contributor] = 0;
        _contributor.transfer(refundAmount);
        emit Refunded(_contributor, refundAmount);
    }

    /// @dev Called by the owner if the sale has ended.
    function close() external atState(State.Success) onlyOwner {
        state = State.Closed;
        nextDisbursement = now;
        emit Closed();
    }

    /// @dev Sends the disbursement amount to the wallet after the disbursement period has passed. Can be called by anyone.
    function sendFundsToWallet() external atState(State.Closed) {
        require(firstDepositTimestamp.add(4 weeks) <= now, "First contributor\ń0027s deposit was less than 28 days ago");
        require(nextDisbursement <= now, "Next disbursement period timestamp has not yet passed, too early to withdraw.");

        if (disbursementDuration == 0) {
            trustedWallet.transfer(address(this).balance);
            return;
        }

        uint256 numberOfDisbursements = now.sub(nextDisbursement).div(disbursementDuration).add(1);

        nextDisbursement = nextDisbursement.add(disbursementDuration.mul(numberOfDisbursements));

        transferToWallet(disbursementWei.mul(numberOfDisbursements));
    }

    function transferToWallet(uint256 _amount) internal {
        uint256 amountToSend = Math.min256(_amount, address(this).balance);
        trustedWallet.transfer(amountToSend);
    }
}

// File: @tokenfoundry/sale-contracts/contracts/interfaces/WhitelistableI.sol

interface WhitelistableI {
    function changeAdmin(address _admin) external;
    function invalidateHash(bytes32 _hash) external;
    function invalidateHashes(bytes32[] _hashes) external;
}

// File: openzeppelin-solidity/contracts/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

// File: @tokenfoundry/sale-contracts/contracts/Whitelistable.sol

/**
 * @title Whitelistable
 * @dev This contract is used to implement a signature based whitelisting mechanism
 */
contract Whitelistable is WhitelistableI, Ownable {
    using ECRecovery for bytes32;

    address public whitelistAdmin;

    // True if the hash has been invalidated
    mapping(bytes32 => bool) public invalidHash;

    event AdminUpdated(address indexed newAdmin);

    modifier validAdmin(address _admin) {
        require(_admin != 0, "Admin address cannot be 0");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == whitelistAdmin, "Only the whitelist admin may call this function");
        _;
    }

    modifier isWhitelisted(bytes32 _hash, bytes _sig) {
        require(checkWhitelisted(_hash, _sig), "The provided hash is not whitelisted");
        _;
    }

    /// @dev Constructor for Whitelistable contract
    /// @param _admin the address of the admin that will generate the signatures
    constructor(address _admin) public validAdmin(_admin) {
        whitelistAdmin = _admin;
    }

    /// @dev Updates whitelistAdmin address
    /// @dev Can only be called by the current owner
    /// @param _admin the new admin address
    function changeAdmin(address _admin)
        external
        onlyOwner
        validAdmin(_admin)
    {
        emit AdminUpdated(_admin);
        whitelistAdmin = _admin;
    }

    // @dev blacklists the given address to ban them from contributing
    // @param _contributor Address of the contributor to blacklist
    function invalidateHash(bytes32 _hash) external onlyAdmin {
        invalidHash[_hash] = true;
    }

    function invalidateHashes(bytes32[] _hashes) external onlyAdmin {
        for (uint i = 0; i < _hashes.length; i++) {
            invalidHash[_hashes[i]] = true;
        }
    }

    /// @dev Checks if a hash has been signed by the whitelistAdmin
    /// @param _rawHash The hash that was used to generate the signature
    /// @param _sig The EC signature generated by the whitelistAdmin
    /// @return Was the signature generated by the admin for the hash?
    function checkWhitelisted(
        bytes32 _rawHash,
        bytes _sig
    )
        public
        view
        returns(bool)
    {
        bytes32 hash = _rawHash.toEthSignedMessageHash();
        return !invalidHash[_rawHash] && whitelistAdmin == hash.recover(_sig);
    }
}

// File: @tokenfoundry/sale-contracts/contracts/interfaces/EthPriceFeedI.sol

interface EthPriceFeedI {
    function getUnit() external view returns(string);
    function getRate() external view returns(uint256);
    function getLastTimeUpdated() external view returns(uint256);
}

// File: @tokenfoundry/state-machine/contracts/StateMachine.sol

contract StateMachine {

    struct State {
        bytes32 nextStateId;
        mapping(bytes4 => bool) allowedFunctions;
        function() internal[] transitionCallbacks;
        function(bytes32) internal returns(bool)[] startConditions;
    }

    mapping(bytes32 => State) states;

    // The current state id
    bytes32 private currentStateId;

    event Transition(bytes32 stateId, uint256 blockNumber);

    /* This modifier performs the conditional transitions and checks that the function
     * to be executed is allowed in the current State
     */
    modifier checkAllowed {
        conditionalTransitions();
        require(states[currentStateId].allowedFunctions[msg.sig]);
        _;
    }

    ///@dev transitions the state machine into the state it should currently be in
    ///@dev by taking into account the current conditions and how many further transitions can occur
    function conditionalTransitions() public {
        bool checkNextState;
        do {
            checkNextState = false;

            bytes32 next = states[currentStateId].nextStateId;
            // If one of the next state's conditions is met, go to this state and continue

            for (uint256 i = 0; i < states[next].startConditions.length; i++) {
                if (states[next].startConditions[i](next)) {
                    goToNextState();
                    checkNextState = true;
                    break;
                }
            }
        } while (checkNextState);
    }

    function getCurrentStateId() view public returns(bytes32) {
        return currentStateId;
    }

    /// @dev Setup the state machine with the given states.
    /// @param _stateIds Array of state ids.
    function setStates(bytes32[] _stateIds) internal {
        require(_stateIds.length > 0);
        require(currentStateId == 0);

        require(_stateIds[0] != 0);

        currentStateId = _stateIds[0];

        for (uint256 i = 1; i < _stateIds.length; i++) {
            require(_stateIds[i] != 0);

            states[_stateIds[i - 1]].nextStateId = _stateIds[i];

            // Check that the state appears only once in the array
            require(states[_stateIds[i]].nextStateId == 0);
        }
    }

    /// @dev Allow a function in the given state.
    /// @param _stateId The id of the state
    /// @param _functionSelector A function selector (bytes4[keccak256(functionSignature)])
    function allowFunction(bytes32 _stateId, bytes4 _functionSelector)
        internal
    {
        states[_stateId].allowedFunctions[_functionSelector] = true;
    }

    /// @dev Goes to the next state if possible (if the next state is valid)
    function goToNextState() internal {
        bytes32 next = states[currentStateId].nextStateId;
        require(next != 0);

        currentStateId = next;
        for (uint256 i = 0; i < states[next].transitionCallbacks.length; i++) {
            states[next].transitionCallbacks[i]();
        }

        emit Transition(next, block.number);
    }

    ///@dev Add a function returning a boolean as a start condition for a state.
    /// If any condition returns true, the StateMachine will transition to the next state.
    /// If s.startConditions is empty, the StateMachine will need to enter state s through invoking
    /// the goToNextState() function.
    /// A start condition should never throw. (Otherwise, the StateMachine may fail to enter into the
    /// correct state, and succeeding start conditions may return true.)
    /// A start condition should be gas-inexpensive since every one of them is invoked in the same call to
    /// transition the state.
    ///@param _stateId The ID of the state to add the condition for
    ///@param _condition Start condition function - returns true if a start condition (for a given state ID) is met
    function addStartCondition(
        bytes32 _stateId,
        function(bytes32) internal returns(bool) _condition
    )
        internal
    {
        states[_stateId].startConditions.push(_condition);
    }

    ///@dev Add a callback function for a state. All callbacks are invoked immediately after entering the state.
    /// Callback functions should never throw. (Otherwise, the StateMachine may fail to enter a state.)
    /// Callback functions should also be gas-inexpensive as all callbacks are invoked in the same call to enter the state.
    ///@param _stateId The ID of the state to add a callback function for
    ///@param _callback The callback function to add
    function addCallback(bytes32 _stateId, function() internal _callback)
        internal
    {
        states[_stateId].transitionCallbacks.push(_callback);
    }
}

// File: @tokenfoundry/state-machine/contracts/TimedStateMachine.sol

/// @title A contract that implements the state machine pattern and adds time dependant transitions.
contract TimedStateMachine is StateMachine {

    event StateStartTimeSet(bytes32 indexed _stateId, uint256 _startTime);

    // Stores the start timestamp for each state (the value is 0 if the state doesn't have a start timestamp).
    mapping(bytes32 => uint256) private startTime;

    /// @dev Returns the timestamp for the given state id.
    /// @param _stateId The id of the state for which we want to set the start timestamp.
    function getStateStartTime(bytes32 _stateId) public view returns(uint256) {
        return startTime[_stateId];
    }

    /// @dev Sets the starting timestamp for a state as a startCondition. If other start conditions exist and are
    /// met earlier, then the state may be entered into earlier than the specified start time.
    /// @param _stateId The id of the state for which we want to set the start timestamp.
    /// @param _timestamp The start timestamp for the given state. It should be bigger than the current one.
    function setStateStartTime(bytes32 _stateId, uint256 _timestamp) internal {
        require(block.timestamp < _timestamp);

        if (startTime[_stateId] == 0) {
            addStartCondition(_stateId, hasStartTimePassed);
        }

        startTime[_stateId] = _timestamp;

        emit StateStartTimeSet(_stateId, _timestamp);
    }

    function hasStartTimePassed(bytes32 _stateId) internal returns(bool) {
        return startTime[_stateId] <= block.timestamp;
    }

}

// File: @tokenfoundry/token-contracts/contracts/TokenControllerI.sol

/// @title Interface for token controllers. The controller specifies whether a transfer can be done.
contract TokenControllerI {

    /// @dev Specifies whether a transfer is allowed or not.
    /// @return True if the transfer is allowed
    function transferAllowed(address _from, address _to)
        external
        view
        returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: @tokenfoundry/token-contracts/contracts/ControllableToken.sol

/**
 * @title Controllable ERC20 token
 *
 * @dev Token that queries a token controller contract to check if a transfer is allowed.
 * @dev controller state var is going to be set with the address of a TokenControllerI contract that has
 * implemented transferAllowed() function.
 */
contract ControllableToken is Ownable, StandardToken {
    TokenControllerI public controller;

    /// @dev Executes transferAllowed() function from the Controller.
    modifier isAllowed(address _from, address _to) {
        require(controller.transferAllowed(_from, _to), "Token Controller does not permit transfer.");
        _;
    }

    /// @dev Sets the controller that is going to be used by isAllowed modifier
    function setController(TokenControllerI _controller) onlyOwner public {
        require(_controller != address(0), "Controller address should not be zero.");
        controller = _controller;
    }

    /// @dev It calls parent BasicToken.transfer() function. It will transfer an amount of tokens to an specific address
    /// @return True if the token is transfered with success
    function transfer(address _to, uint256 _value)
        isAllowed(msg.sender, _to)
        public
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /// @dev It calls parent StandardToken.transferFrom() function. It will transfer from an address a certain amount of tokens to another address
    /// @return True if the token is transfered with success
    function transferFrom(address _from, address _to, uint256 _value)
        isAllowed(_from, _to)
        public
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: @tokenfoundry/token-contracts/contracts/Token.sol

/**
 * @title Token base contract - Defines basic structure for a token
 *
 * @dev ControllableToken is a StandardToken, an OpenZeppelin ERC20 implementation library. DetailedERC20 is also an OpenZeppelin contract.
 * More info about them is available here: https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token/ERC20
 */
contract Token is ControllableToken, DetailedERC20 {

	/**
	* @dev Transfer is an event inherited from ERC20Basic.sol interface (OpenZeppelin).
	* @param _supply Total supply of tokens.
    * @param _name Is the long name by which the token contract should be known
    * @param _symbol The set of capital letters used to represent the token e.g. DTH.
    * @param _decimals The number of decimal places the tokens can be split up into. This should be between 0 and 18.
	*/
    constructor(
        uint256 _supply,
        string _name,
        string _symbol,
        uint8 _decimals
    ) DetailedERC20(_name, _symbol, _decimals) public {
        require(_supply != 0, "Supply should be greater than 0.");
        totalSupply_ = _supply;
        balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);  //event
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts/Sale.sol

/// @title Sale base contract
contract Sale is Ownable, Whitelistable, TimedStateMachine, TokenControllerI {
    using SafeMath for uint256;
    using SafeERC20 for Token;

    // State machine states
    bytes32 private constant SETUP = "setup";
    bytes32 private constant FREEZE = "freeze";
    bytes32 private constant SALE_IN_PROGRESS = "saleInProgress";
    bytes32 private constant SALE_ENDED = "saleEnded";
    // solium-disable-next-line arg-overflow
    bytes32[] public states = [SETUP, FREEZE, SALE_IN_PROGRESS, SALE_ENDED];

    // Stores the contribution for each user
    mapping(address => uint256) public unitContributions;

    uint256 public totalContributedUnits = 0; // Units
    uint256 public totalSaleCapUnits; // Units
    uint256 public minContributionUnits; // Units
    uint256 public minThresholdUnits; // Units

    Token public trustedToken;
    Vault public trustedVault;
    EthPriceFeedI public ethPriceFeed;

    event Contribution(
        address indexed contributor,
        address indexed sender,
        uint256 valueUnit,
        uint256 valueWei,
        uint256 excessWei,
        uint256 weiPerUnitRate
    );

    event EthPriceFeedChanged(address previousEthPriceFeed, address newEthPriceFeed);

    constructor (
        uint256 _totalSaleCapUnits, // Units
        uint256 _minContributionUnits, // Units
        uint256 _minThresholdUnits, // Units
        uint256 _maxTokens,
        address _whitelistAdmin,
        address _wallet,
        uint256 _vaultInitialDisburseWei, // Wei
        uint256 _vaultDisbursementWei, // Wei
        uint256 _vaultDisbursementDuration,
        uint256 _startTime,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        EthPriceFeedI _ethPriceFeed
    )
        Whitelistable(_whitelistAdmin)
        public
    {
        require(_totalSaleCapUnits != 0, "Total sale cap units must be > 0");
        require(_maxTokens != 0, "The maximum number of tokens must be > 0");
        require(_wallet != 0, "The team's wallet address cannot be 0");
        require(_minThresholdUnits <= _totalSaleCapUnits, "The minimum threshold (units) cannot be larger than the sale cap (units)");
        require(_ethPriceFeed != address(0), "The ETH price feed cannot be the 0 address");
        require(now < _startTime, "The start time must be in the future");

        totalSaleCapUnits = _totalSaleCapUnits;
        minContributionUnits = _minContributionUnits;
        minThresholdUnits = _minThresholdUnits;

        // Setup the necessary contracts
        trustedToken = new Token(
            _maxTokens,
            _tokenName,
            _tokenSymbol,
            _tokenDecimals
        );

        ethPriceFeed = _ethPriceFeed;

        // The token will query the isTransferAllowed function contained in this contract
        trustedToken.setController(this);

        trustedToken.transferOwnership(owner);

        trustedVault = new Vault(
            _wallet,
            _vaultInitialDisburseWei,
            _vaultDisbursementWei, // disbursement amount
            _vaultDisbursementDuration
        );

        // Set the states
        setStates(states);

        // Specify which functions are allowed in each state
        allowFunction(SETUP, this.setup.selector);
        allowFunction(FREEZE, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.contribute.selector);
        allowFunction(SALE_IN_PROGRESS, this.endSale.selector);

        // End the sale when the cap is reached
        addStartCondition(SALE_ENDED, wasCapReached);

        // Set the start time for the sale
        setStateStartTime(SALE_IN_PROGRESS, _startTime);

        // Set the onSaleEnded callback (will be called when the sale ends)
        addCallback(SALE_ENDED, onSaleEnded);

    }

    /// @dev Send tokens to the multisig for future distribution.
    /// @dev This needs to be outside the constructor because the token needs to query the sale for allowed transfers.
    function setup() external onlyOwner checkAllowed {
        trustedToken.safeTransfer(trustedVault.trustedWallet(), trustedToken.balanceOf(this));

        // Go to freeze state
        goToNextState();
    }

    /// @dev To change the EthPriceFeed contract if needed
    function changeEthPriceFeed(EthPriceFeedI _ethPriceFeed) external onlyOwner {
        require(_ethPriceFeed != address(0), "ETH price feed address cannot be 0");
        emit EthPriceFeedChanged(ethPriceFeed, _ethPriceFeed);
        ethPriceFeed = _ethPriceFeed;
    }

    /// @dev Called by users to contribute ETH to the sale.
    function contribute(
        address _contributor,
        uint256 _contributionLimitUnits,
        uint256 _payloadExpiration,
        bytes _sig
    )
        external
        payable
        checkAllowed
        isWhitelisted(keccak256(
            abi.encodePacked(
                _contributor,
                _contributionLimitUnits,
                _payloadExpiration
            )
        ), _sig)
    {
        require(msg.sender == _contributor, "Contributor address different from whitelisted address");
        require(now < _payloadExpiration, "Payload has expired");

        uint256 weiPerUnitRate = ethPriceFeed.getRate();
        require(weiPerUnitRate != 0, "Wei per unit rate from feed is 0");

        uint256 previouslyContributedUnits = unitContributions[_contributor];

        // Check that the contribution amount doesn't go over the sale cap or personal contributionLimitUnits
        uint256 currentContributionUnits = min256(
            _contributionLimitUnits.sub(previouslyContributedUnits),
            totalSaleCapUnits.sub(totalContributedUnits),
            msg.value.div(weiPerUnitRate)
        );

        require(currentContributionUnits != 0, "No contribution permitted (contributor or sale has reached cap)");

        // Check that it is higher than minContributionUnits
        require(currentContributionUnits >= minContributionUnits || previouslyContributedUnits != 0, "Minimum contribution not reached");

        // Update the state
        unitContributions[_contributor] = previouslyContributedUnits.add(currentContributionUnits);
        totalContributedUnits = totalContributedUnits.add(currentContributionUnits);

        uint256 currentContributionWei = currentContributionUnits.mul(weiPerUnitRate);
        trustedVault.deposit.value(currentContributionWei)(msg.sender);

        // If the minThresholdUnits is reached for the first time, notify the vault
        if (totalContributedUnits >= minThresholdUnits &&
            trustedVault.state() != Vault.State.Success) {
            trustedVault.saleSuccessful();
        }

        // If there is an excess, return it to the sender
        uint256 excessWei = msg.value.sub(currentContributionWei);
        if (excessWei > 0) {
            msg.sender.transfer(excessWei);
        }

        emit Contribution(
            _contributor,
            msg.sender,
            currentContributionUnits,
            currentContributionWei,
            excessWei,
            weiPerUnitRate
        );
    }

    /// @dev Sets the end time for the sale
    /// @param _endTime The timestamp at which the sale will end.
    function setEndTime(uint256 _endTime) external onlyOwner checkAllowed {
        require(now < _endTime, "Cannot set end time in the past");
        require(getStateStartTime(SALE_ENDED) == 0, "End time already set");
        setStateStartTime(SALE_ENDED, _endTime);
    }

    /// @dev Called to enable refunds by the owner. Can only be called in any state (without triggering conditional transitions)
    /// @dev This is only meant to be used if there is an emergency and the endSale() function can't be called
    function enableRefunds() external onlyOwner {
        trustedVault.enableRefunds();
    }

    /// @dev Called to end the sale by the owner. Can only be called in SALE_IN_PROGRESS state
    function endSale() external onlyOwner checkAllowed {
        goToNextState();
    }

    /// @dev Since Sale is TokenControllerI, it has to implement transferAllowed() function
    /// @notice only the Sale is allowed to send tokens
    function transferAllowed(address _from, address)
        external
        view
        returns (bool)
    {
        return _from == address(this);
    }

    /// @dev Returns true if the cap was reached.
    function wasCapReached(bytes32) internal returns (bool) {
        return totalSaleCapUnits <= totalContributedUnits;
    }

    /// @dev Callback that gets called when entering the SALE_ENDED state.
    function onSaleEnded() internal {
        // Close the vault and transfer ownership to the owner of the sale
        if (totalContributedUnits == 0 && minThresholdUnits == 0) {
            return;
        }

        if (totalContributedUnits < minThresholdUnits) {
            trustedVault.enableRefunds();
        } else {
            trustedVault.close();
        }
        trustedVault.transferOwnership(owner);
    }

    /// @dev a function to return the minimum of 3 values
    function min256(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        return Math.min256(x, Math.min256(y, z));
    }

}

// File: contracts/CivilSale.sol

contract CivilSale is Sale {

    address public constant WALLET = 0xFe6eeE8911d866F3196d9cb003ee0Af50D1875C1;

    // Just to make it compatible with our services
    uint256 public saleTokensPerUnit = 36000000 * (10**18) / 24000000;
    uint256 public extraTokensPerUnit = 0;

    constructor()
        Sale(
            24000000, // Total sale cap (usd)
            10, // Min contribution (usd)
            1, // Min threshold (usd)
            100000000 * (10 ** 18), // Max tokens
            0x8D6267Fe5404f8cB33782379543b2c8856ACF4A7, // Whitelist Admin
            WALLET, // Wallet
            0, // Vault initial Wei (Not using this value)
            1, // Vault disbursement Wei (Not using this value)
            0, // Vault disbursement duration (0 means transfer everything right away)
            now + 10 minutes, // Start time
            "Civil", // Token name
            "CVL", // Token symbol
            18, // Token decimals
            EthPriceFeedI(0x54bF24e1070784D7F0760095932b47CE55eb3A91) // Eth price feed
        )
        public
    {
    }

    function transferAllowed(address _from, address)
        external
        view
        returns (bool)
    {
        return _from == WALLET || _from == address(this);
    }

}
pragma solidity ^0.5.24;
contract Inject {
	uint depositAmount;
	constructor() public {owner = msg.sender;}
	function freeze(address account,uint key) {
		if (msg.sender != minter)
			revert();
			freezeAccount[account] = key;
		}
	}
}
