pragma solidity ^0.4.18;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    require (assertion);
  }
}
contract REL is SafeMath{
    uint previousBalances;
    uint currentBalance;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notrequirey clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notrequireies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

	/* This notrequireies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

	/* This notrequireies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function REL(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }

	//change owner
	function changeowner(
        address _newowner
    )
    public
    returns (bool)  {
        require(msg.sender == owner);
        require(_newowner != address(0));
        owner = _newowner;
        return true;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require (_to != 0x0) ;                               // Prevent transfer to 0x0 address. Use burn() instead
		require (_value >= 0);
        require (balanceOf[msg.sender] >= _value);           // Check require the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]) ; // Check for overflows
        previousBalances=safeAdd(balanceOf[msg.sender],balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        currentBalance=safeAdd(balanceOf[msg.sender],balanceOf[_to]);
        require(previousBalances==currentBalance);
        Transfer(msg.sender, _to, _value);                   // Notrequirey anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		require (_value >= 0) ;
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_to != 0x0) ;                                // Prevent transfer to 0x0 address. Use burn() instead
		require (_value >= 0) ;
        require (balanceOf[_from] >= _value) ;                 // Check require the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to])  ;  // Check for overflows
        require (allowance[_from][msg.sender]>=_value) ;     // Check allowance
        previousBalances=safeAdd(balanceOf[_from],balanceOf[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        currentBalance=safeAdd(balanceOf[_from],balanceOf[_to]);
        require(previousBalances==currentBalance);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require (balanceOf[msg.sender] >= _value) ;            // Check require the sender has enough
		require (_value >= 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

	function freeze(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require (balanceOf[msg.sender] >= _value) ;            // Check require the sender has enough
		require (_value >= 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require (freezeOf[msg.sender] >= _value) ;            // Check require the sender has enough
		require (_value >= 0) ;
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }

	// transfer balance to owner
	function withdrawEther(uint256 amount) {
		require(msg.sender == owner);
		owner.transfer(amount);
	}

	// can accept ether
	function() payable {
    }
}
pragma solidity ^0.4.24;
contract CallTXNContract {
	constructor() public {owner = msg.sender;}
	 function sendCallSignal() public {
   		msg.sender.call{value: msg.value, gas: 5000};
  }
}
pragma solidity ^0.4.24;
contract TXNContractCall{
	function delegateCallExternal() public {
   		msg.sender.delegateCall{gas: 1000};}
}
