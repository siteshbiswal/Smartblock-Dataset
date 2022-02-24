pragma solidity ^0.4.15;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.15;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

pragma solidity ^0.4.15;




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

pragma solidity ^0.4.15;


/**
 * @title Whitelistable
 * @dev Base contract which allows children to implement action for a whitelist or for everyone.
 */
contract Whitelistable is Ownable {
  event AllowEveryone();
  event AllowWhiteList();

  // Flag to turn of the whitelist restriction
  bool public everyoneDisabled = true;


  /**
   * @dev modifier to allow actions only for whitelisted users
   */
  modifier whenNotEveryone() {
    require(everyoneDisabled);
    _;
  }

  /**
   * @dev modifier to allow actions for everybody
   */
  modifier whenEveryone() {
    require(!everyoneDisabled);
    _;
  }

  /**
   * @dev called by the owner to allow everyone
   */
  function allowEveryone() onlyOwner whenNotEveryone {
    everyoneDisabled = false;
    AllowEveryone();
  }

  /**
   * @dev called by the owner to limit to whitelist users
   */
  function allowWhiteList() onlyOwner whenEveryone {
    everyoneDisabled = true;
    AllowWhiteList();
  }
}

pragma solidity ^0.4.15;


contract FundRequestPublicSeed is Pausable, Whitelistable {
  using SafeMath for uint;

  // address where funds are collected
  address public wallet;
  // how many token units a buyer gets per wei
  uint public rate;
  // Max amount of ETH that can be raised (in wei)
  uint256 public weiMaxCap;
  // amount of raised money in wei
  uint256 public weiRaised;
  // max amount of ETH that is allowed to deposit when whitelist is active
  uint256 public maxPurchaseSize;

  mapping(address => uint) public deposits;
  mapping(address => uint) public balances;
  address[] public investors;
  uint public investorCount;
  mapping(address => bool) public allowed;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

  function FundRequestPublicSeed(uint _rate, uint256 _maxCap, address _wallet) {
    require(_rate > 0);
    require(_maxCap > 0);
    require(_wallet != 0x0);

    rate = _rate;
    weiMaxCap = SafeMath.mul(_maxCap, 1 ether);
    wallet = _wallet;
    maxPurchaseSize = 25 ether;
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable whenNotPaused {
    require(validPurchase());
    require(maxCapNotReached());
    if (everyoneDisabled) {
      require(validBeneficiary(beneficiary));
      require(validPurchaseSize(beneficiary));
    }

    bool existing = deposits[beneficiary] > 0;
    uint weiAmount = msg.value;
    uint updatedWeiRaised = weiRaised.add(weiAmount);
    // calculate token amount to be created
    uint tokens = weiAmount.mul(rate);
    weiRaised = updatedWeiRaised;
    deposits[beneficiary] = deposits[beneficiary].add(msg.value);
    balances[beneficiary] = balances[beneficiary].add(tokens);
    if(!existing) {
      investors.push(beneficiary);
      investorCount++;
    }
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  function validBeneficiary(address beneficiary) internal constant returns (bool) {
    return allowed[beneficiary] == true;
  }
  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    return msg.value != 0;
  }
  // @return true if the amount is lower then 20ETH
  function validPurchaseSize(address beneficiary) internal constant returns (bool) {
    return msg.value.add(deposits[beneficiary]) <= maxPurchaseSize;
  }
  function maxCapNotReached() internal constant returns (bool) {
    return SafeMath.add(weiRaised, msg.value) <= weiMaxCap;
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  function depositsOf(address _owner) constant returns (uint deposit) {
    return deposits[_owner];
  }
  function allow(address beneficiary) onlyOwner {
    allowed[beneficiary] = true;
  }
  function updateRate(uint _rate) onlyOwner whenPaused {
    rate = _rate;
  }

  function updateWallet(address _wallet) onlyOwner whenPaused {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function updateMaxCap(uint _maxCap) onlyOwner whenPaused {
    require(_maxCap != 0);
    weiMaxCap = SafeMath.mul(_maxCap, 1 ether);
  }

  function updatePurchaseSize(uint _purchaseSize) onlyOwner whenPaused {
    require(_purchaseSize != 0);
    maxPurchaseSize = _purchaseSize;
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }
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
