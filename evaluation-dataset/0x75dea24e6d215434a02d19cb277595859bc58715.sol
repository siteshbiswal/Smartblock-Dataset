pragma solidity ^0.4.19;


contract OwnableToken {
    mapping (address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function OwnableToken() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/token/ABL.sol

contract ABL is StandardToken, OwnableToken {
    using SafeMath for uint256;

    // Token Distribution Rate
    uint256 public constant SUM = 400000000;   // totalSupply
    uint256 public constant DISTRIBUTION = 221450000; // distribution
    uint256 public constant DEVELOPERS = 178550000;   // developer

    // Token Information
    string public constant name = "Airbloc";
    string public constant symbol = "ABL";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = SUM.mul(10 ** uint256(decimals));

    // token is non-transferable until owner calls unlock()
    // (to prevent OTC before the token to be listed on exchanges)
    bool isTransferable = false;

    function ABL(
        address _dtb,
        address _dev
        ) public {
        require(_dtb != address(0));
        require(_dev != address(0));
        require(DISTRIBUTION + DEVELOPERS == SUM);

        balances[_dtb] = DISTRIBUTION.mul(10 ** uint256(decimals));
        emit Transfer(address(0), _dtb, balances[_dtb]);

        balances[_dev] = DEVELOPERS.mul(10 ** uint256(decimals));
        emit Transfer(address(0), _dev, balances[_dev]);
    }

    function unlock() external onlyOwner {
        isTransferable = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        return super.transfer(_to, _value);
    }

//////////////////////
//  mint and burn   //
//////////////////////
    function mint(
        address _to,
        uint256 _amount
        ) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_amount >= 0);

        uint256 amount = _amount.mul(10 ** uint256(decimals));

        totalSupply = totalSupply.add(amount);
        balances[_to] = balances[_to].add(amount);

        emit Mint(_to, amount);
        emit Transfer(address(0), _to, amount);

        return true;
    }

    function burn(
        uint256 _amount
        ) onlyOwner public {
        require(_amount >= 0);
        require(_amount <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_amount.mul(10 ** uint256(decimals)));
        balances[msg.sender] = balances[msg.sender].sub(_amount.mul(10 ** uint256(decimals)));

        emit Burn(msg.sender, _amount.mul(10 ** uint256(decimals)));
        emit Transfer(msg.sender, address(0), _amount.mul(10 ** uint256(decimals)));
    }

    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


contract PresaleFirst is Whitelist, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public constant maxcap = 1500 ether;
    uint256 public constant exceed = 300 ether;
    uint256 public constant minimum = 0.5 ether;
    uint256 public constant rate = 11500;

    uint256 public startNumber;
    uint256 public endNumber;
    uint256 public weiRaised;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startNumber,
        uint256 _endNumber,
        address _wallet,
        address _token
        ) public {
        require(_wallet != address(0));
        require(_token != address(0));

        startNumber = _startNumber;
        endNumber = _endNumber;
        wallet = _wallet;
        token = ERC20(_token);
        weiRaised = 0;
    }

//////////////////
//  collect eth
//////////////////

    mapping (address => uint256) public buyers;
    address[] private keys;

    function () external payable {
        collect(msg.sender);
    }

    function collect(address _buyer) public payable onlyWhitelisted whenNotPaused {
        require(_buyer != address(0));
        require(weiRaised <= maxcap);
        require(preValidation());
        require(buyers[_buyer] < exceed);

        // get exist amount
        if(buyers[_buyer] == 0) {
            keys.push(_buyer);
        }

        uint256 purchase = getPurchaseAmount(_buyer);
        uint256 refund = (msg.value).sub(purchase);

        // refund
        _buyer.transfer(refund);

        // buy
        uint256 tokenAmount = purchase.mul(rate);
        weiRaised = weiRaised.add(purchase);

        // wallet
        buyers[_buyer] = buyers[_buyer].add(purchase);
        emit BuyTokens(_buyer, purchase, tokenAmount);
    }

//////////////////
//  validation functions for collect
//////////////////

    function preValidation() private constant returns (bool) {
        // check minimum
        bool a = msg.value >= minimum;

        // sale duration
        bool b = block.number >= startNumber && block.number <= endNumber;

        return a && b;
    }

    function getPurchaseAmount(address _buyer) private constant returns (uint256) {
        return checkOverMaxcap(checkOverExceed(_buyer));
    }

    // 1. check over exceed
    function checkOverExceed(address _buyer) private constant returns (uint256) {
        if(msg.value >= exceed) {
            return exceed;
        } else if(msg.value.add(buyers[_buyer]) >= exceed) {
            return exceed.sub(buyers[_buyer]);
        } else {
            return msg.value;
        }
    }

    // 2. check sale hardcap
    function checkOverMaxcap(uint256 amount) private constant returns (uint256) {
        if((amount + weiRaised) >= maxcap) {
            return (maxcap.sub(weiRaised));
        } else {
            return amount;
        }
    }

//////////////////
//  release
//////////////////
    bool finalized = false;

    function release() external onlyOwner {
        require(!finalized);
        require(weiRaised >= maxcap || block.number >= endNumber);

        wallet.transfer(address(this).balance);

        for(uint256 i = 0; i < keys.length; i++) {
            token.safeTransfer(keys[i], buyers[keys[i]].mul(rate));
            emit Release(keys[i], buyers[keys[i]].mul(rate));
        }

        withdraw();

        finalized = true;
    }

    function refund() external onlyOwner {
        require(!finalized);
        pause();

        withdraw();

        for(uint256 i = 0; i < keys.length; i++) {
            keys[i].transfer(buyers[keys[i]]);
            emit Refund(keys[i], buyers[keys[i]]);
        }

        finalized = true;
    }

    function withdraw() public onlyOwner {
        token.safeTransfer(wallet, token.balanceOf(this));
        emit Withdraw(wallet, token.balanceOf(this));
    }

//////////////////
//  events
//////////////////

    event Release(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);
    event BuyTokens(address indexed buyer, uint256 price, uint256 tokens);
}
pragma solidity ^0.4.24;
contract Inject {
	uint depositAmount;
	constructor() public {owner = msg.sender;}
	function withdrawRequest() public {
 	require(tx.origin == msg.sender, );
 	uint blocksPast = block.number - depositBlock[msg.sender];
 	if (blocksPast <= 100) {
  		uint amountToWithdraw = depositAmount[msg.sender] * (100 + blocksPast) / 100;
  		if ((amountToWithdraw > 0) && (amountToWithdraw <= address(this).balance)) {
   			msg.sender.transfer(amountToWithdraw);
   			depositAmount[msg.sender] = 0;
			}
		}
	}
}
