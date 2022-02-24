pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

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




contract owned { //Contract used to only allow the owner to call some functions
	address public owner;

	function owned() public {
	owner = msg.sender;
	}

	modifier onlyOwner {
	require(msg.sender == owner);
	_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
	owner = newOwner;
	}
}


contract TokenERC20 {

	using SafeMath for uint256;
	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals = 8;
	//
	uint256 public totalSupply;


	// This creates an array with all balances
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	// This generates a public event on the blockchain that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);

	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);


	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
	}


	function _transfer(address _from, address _to, uint _value) internal {
		// Prevent transfer to 0x0 address. Use burn() instead
		require(_to != 0x0);
		// Check for overflows
		// Save this for an assertion in the future
		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		// Subtract from the sender
		balanceOf[_from] = balanceOf[_from].sub(_value);
		// Add the same to the recipient
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}


	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}


	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}


	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}


	function burn(uint256 _value) public returns (bool success) {
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
		totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
		emit Burn(msg.sender, _value);
		return true;
	}



	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
		allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
		totalSupply = totalSupply.sub(_value);                              // Update totalSupply
		emit Burn(_from, _value);
		return true;
	}


}

/******************************************/
/*       IMEXToken STARTS HERE       */
/******************************************/

contract IMEXToken is owned, TokenERC20  {

	//Modify these variables
	uint256 _initialSupply=420000000;
	string _tokenName="COIMEX";
	string _tokenSymbol="IMEX";
	address wallet1 = 0x3d41E1d1941957FB21c2d3503E59a69aa7990370;
	address wallet2 = 0xE5AA70C5f021992AceE6E85E6Dd187eE228f9690;
	address wallet3 = 0x55C7Cbb819C601cB6333a1398703EeD610cCcF40;
	uint256 public startTime;

	mapping (address => bool) public frozenAccount;

	/* This generates a public event on the blockchain that will notify clients */
	event FrozenFunds(address target, bool frozen);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function IMEXToken( ) TokenERC20(_initialSupply, _tokenName, _tokenSymbol) public {

		startTime = now;

		balanceOf[wallet1] = totalSupply.mul(1).div(100);
		balanceOf[wallet2] = totalSupply.mul(25).div(100);
		balanceOf[wallet3] = totalSupply.mul(74).div(100);
	}

	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);

		bool lockedBalance = checkLockedBalance(_from,_value);
		require(lockedBalance);

		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}

	function checkLockedBalance(address wallet, uint256 _value) internal returns (bool){
		if(wallet==wallet1){
			if(now<startTime + 183 * 1 days){
				return balanceOf[wallet1].sub(_value)>=totalSupply.mul(1).div(100)? true : false;
			}else{
				return true;
			}
		}else if(wallet==wallet3){
			if(now<startTime + 183 * 1 days){
				return balanceOf[wallet3].sub(_value)>=totalSupply.mul(17).div(100)? true : false;
			}else if(now>=startTime + 183 * 1 days && now<startTime + 365 * 1 days){
				return balanceOf[wallet3].sub(_value)>=totalSupply.mul(12).div(100)? true : false;
			}else{
				return true;
			}
		}else{
			return true;
		}

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
