/*
Copyright 2018 Binod Nirvan @ xCrypt (https://www.xcrypt.club)
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

pragma solidity ^0.4.24;

/*
Copyright 2018 Binod Nirvan @ xCrypt (https://www.xcrypt.club)
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/










/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}






/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */



/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */






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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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



///@title This contract enables to create multiple contract administrators.
contract CustomAdmin is Ownable {
  ///List of administrators.
  mapping(address => bool) public admins;

  event AdminAdded(address indexed _address);
  event AdminRemoved(address indexed _address);

  ///@notice Validates if the sender is actually an administrator.
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Access is denied.");
    _;
  }

  ///@notice Adds the specified address to the list of administrators.
  ///@param _address The address to add to the administrator list.
  function addAdmin(address _address) external onlyAdmin returns(bool) {
    require(_address != address(0), "Invalid address.");
    require(!admins[_address], "This address is already an administrator.");

    require(_address != owner, "The owner cannot be added or removed to or from the administrator list.");

    admins[_address] = true;

    emit AdminAdded(_address);
    return true;
  }

  ///@notice Adds multiple addresses to the administrator list.
  ///@param _accounts The wallet addresses to add to the administrator list.
  function addManyAdmins(address[] _accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address cannot be an admin.
      ///The owner is already an admin and cannot be assigned.
      ///The address cannot be an existing admin.
      if(account != address(0) && !admins[account] && account != owner) {
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }

    return true;
  }

  ///@notice Removes the specified address from the list of administrators.
  ///@param _address The address to remove from the administrator list.
  function removeAdmin(address _address) external onlyAdmin returns(bool) {
    require(_address != address(0), "Invalid address.");
    require(admins[_address], "This address isn't an administrator.");

    //The owner cannot be removed as admin.
    require(_address != owner, "The owner cannot be added or removed to or from the administrator list.");

    admins[_address] = false;
    emit AdminRemoved(_address);
    return true;
  }

  ///@notice Removes multiple addresses to the administrator list.
  ///@param _accounts The wallet addresses to add to the administrator list.
  function removeManyAdmins(address[] _accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address can neither be added or removed from this list.
      ///The owner is the super admin and cannot be removed.
      ///The address must be an existing admin in order for it to be removed.
      if(account != address(0) && admins[account] && account != owner) {
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }

    return true;
  }

  ///@notice Checks if an address is an administrator.
  function isAdmin(address _address) public view returns(bool) {
    if(_address == owner) {
      return true;
    }

    return admins[_address];
  }
}



///@title This contract enables you to create pausable mechanism to stop in case of emergency.
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool public paused = false;

  ///@notice Verifies whether the contract is not paused.
  modifier whenNotPaused() {
    require(!paused, "Sorry but the contract isn't paused.");
    _;
  }

  ///@notice Verifies whether the contract is paused.
  modifier whenPaused() {
    require(paused, "Sorry but the contract is paused.");
    _;
  }

  ///@notice Pauses the contract.
  function pause() external onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

  ///@notice Unpauses the contract and returns to normal state.
  function unpause() external onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}
/*
Copyright 2018 Binod Nirvan
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/






///@title Transfer State Contract
///@author Binod Nirvan
///@notice Enables the admins to maintain the transfer state.
///Transfer state when disabled disallows everyone but admins to transfer tokens.
contract TransferState is CustomPausable {
  bool public released = false;

  event TokenReleased(bool _state);

  ///@notice Checks if the supplied address is able to perform transfers.
  ///@param _from The address to check against if the transfer is allowed.
  modifier canTransfer(address _from) {
    if(paused || !released) {
      if(!isAdmin(_from)) {
        revert("Operation not allowed. The transfer state is restricted.");
      }
    }

    _;
  }

  ///@notice This function enables token transfers for everyone.
  function enableTransfers() external onlyAdmin whenNotPaused returns(bool) {
    require(!released, "Invalid operation. The transfer state is no more restricted.");

    released = true;

    emit TokenReleased(released);
    return true;
  }

  ///@notice This function disables token transfers for everyone.
  function disableTransfers() external onlyAdmin whenNotPaused returns(bool) {
    require(released, "Invalid operation. The transfer state is already restricted.");

    released = false;

    emit TokenReleased(released);
    return true;
  }
}
/*
Copyright 2018 Binod Nirvan
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/







///@title Bulk Transfer Contract
///@author Binod Nirvan
///@notice This contract provides features for admins to perform bulk transfers.
contract BulkTransfer is StandardToken, CustomAdmin {
  event BulkTransferPerformed(address[] _destinations, uint256[] _amounts);

  ///@notice Allows only the admins and/or whitelisted applications to perform bulk transfer operation.
  ///@param _destinations The destination wallet addresses to send funds to.
  ///@param _amounts The respective amount of fund to send to the specified addresses.
  function bulkTransfer(address[] _destinations, uint256[] _amounts) public onlyAdmin returns(bool) {
    require(_destinations.length == _amounts.length, "Invalid operation.");

    //Saving gas by determining if the sender has enough balance
    //to post this transaction.
    uint256 requiredBalance = sumOf(_amounts);
    require(balances[msg.sender] >= requiredBalance, "You don't have sufficient funds to transfer amount that large.");

    for (uint256 i = 0; i < _destinations.length; i++) {
      transfer(_destinations[i], _amounts[i]);
    }

    emit BulkTransferPerformed(_destinations, _amounts);
    return true;
  }

  ///@notice Returns the sum of supplied values.
  ///@param _values The collection of values to create the sum from.
  function sumOf(uint256[] _values) private pure returns(uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < _values.length; i++) {
      total = total.add(_values[i]);
    }

    return total;
  }
}
/*
Copyright 2018 Binod Nirvan
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/










/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}




///@title Reclaimable Contract
///@author Binod Nirvan
///@notice Reclaimable contract enables the administrators
///to reclaim accidentally sent Ethers and ERC20 token(s)
///to this contract.
contract Reclaimable is CustomAdmin {
  using SafeERC20 for ERC20;

  ///@notice Transfers all Ether held by the contract to the owner.
  function reclaimEther() external onlyAdmin {
    msg.sender.transfer(address(this).balance);
  }

  ///@notice Transfers all ERC20 tokens held by the contract to the owner.
  ///@param _token The amount of token to reclaim.
  function reclaimToken(address _token) external onlyAdmin {
    ERC20 erc20 = ERC20(_token);
    uint256 balance = erc20.balanceOf(this);
    erc20.safeTransfer(msg.sender, balance);
  }
}
/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http:///www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */






///@title Custom Lockable Contract
///@author Binod Nirvan
///@notice This contract enables xCrypt token admins
///to lock tokens on an individual-wallet basis.
///When tokens are locked for specific wallet,
///they cannot transfer their balances
///until the end of their locking period.
///Furthermore, this feature is created to specifically
///lock bounty, advisory, and team tokens
///for a set period of time.
///This feature once turned off cannot be switched on back again.
contract CustomLockable is CustomAdmin {
  ///Locking list contains list of wallets and their respective release dates.
  mapping(address => uint256) public lockingList;

  ///Signifies if the locking feature can be used.
  ///This feature should be turned off as soon as lockings are created.
  bool public canLock = true;

  event TokenLocked(address indexed _address, uint256 _releaseDate);
  event TokenUnlocked(address indexed _address);
  event LockingDisabled();

  ///@notice Reverts this transfer if the wallet is in the locking list.
  modifier revertIfLocked(address _wallet) {
    require(!isLocked(_wallet), "The operation was cancelled because your tokens are locked.");
    _;
  }

  ///@notice Checks if a wallet is locked for transfers.
  function isLocked(address _wallet) public view returns(bool) {
    uint256 _lockedUntil = lockingList[_wallet];

    if(_lockedUntil > 0 && _lockedUntil > now) {
      return true;
    }

    return false;
  }

  ///@notice Adds the specified address to the locking list.
  ///@param _address The address to add to the locking list.
  ///@param _releaseDate The date when the tokens become avaiable for transfer.
  function addLock(address _address, uint256 _releaseDate) external onlyAdmin returns(bool) {
    require(canLock, "Access is denied. This feature was already disabled by an administrator.");
    require(_address != address(0), "Invalid address.");
    require(!admins[_address], "Cannot lock administrators.");
    require(_address != owner, "Cannot lock the owner.");

    lockingList[_address] = _releaseDate;

    if(_releaseDate > 0) {
      emit TokenLocked(_address, _releaseDate);
    } else {
      emit TokenUnlocked(_address);
    }

    return true;
  }

  ///@notice Adds multiple addresses to the locking list.
  ///@param _accounts The wallet addresses to add to the locking list.
  ///@param _releaseDate The date when the tokens become avaiable for transfer.
  function addManyLocks(address[] _accounts, uint256 _releaseDate) external onlyAdmin returns(bool) {
    require(canLock, "Access is denied. This feature was already disabled by an administrator.");
    require(_releaseDate > 0, "Invalid release date.");

    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address, admins, and owner cannot be locked.
      if(account != address(0) && !admins[account] && account != owner) {
        lockingList[account] = _releaseDate;
        emit TokenLocked(account, _releaseDate);
      }
    }

    return true;
  }

  ///@notice Since locking feature is intended to be used
  ///only for a short span of time, calling this function
  ///will disable the feature completely.
  ///Once locking feature is disable, it cannot be
  ///truned back on thenceforth.
  function disableLocking() external onlyAdmin returns(bool) {
    require(canLock, "The token lock feature is already disabled.");

    canLock = false;
    emit LockingDisabled();
    return true;
  }
}


///@title xCrypt Token Base Contract
///@author Binod Nirvan
///@notice XCRYPT is the first crypto ecosystem with a high added value
///with the heart in its exchange: Hybrid, ready for STO
///and for a marketplace made for the ERC721. We created this
///end to end system which includes a Debit Card
///and a Social Media Trading system which is
///an advanced investment solution, which enables trading
///on one account managed by a skillfull and experienced trader
///using his own funds and joint funds invested by other traders
///in his SMT account. This ecosystem is made to be at the same level
///as the world’s big players, and even surpass them, for we are already
///suitable in this field’s future.
contract TokenBase is StandardToken, TransferState, BulkTransfer, Reclaimable, BurnableToken, CustomLockable {
  //solhint-disable
  uint8 public constant decimals = 18;
  string public constant name = "xCrypt Token";
  string public constant symbol = "XCT";
  //solhint-enable

  uint256 internal constant MILLION = 1000000 * 1 ether;
  uint256 public constant MAX_SUPPLY = 200 * MILLION;
  uint256 public constant INITIAL_SUPPLY = 130 * MILLION;

  event Mint(address indexed to, uint256 amount);

  constructor() public {
    mintTokens(msg.sender, INITIAL_SUPPLY);
  }

  ///@notice Transfers the specified value of XCT tokens to the destination address.
  //Transfers can only happen when the transfer state is enabled.
  //Transfer state can only be enabled after the end of the crowdsale.
  ///@dev This function is overridden to leverage transfer state and lockable feature.
  ///@param _to The destination wallet address to transfer funds to.
  ///@param _value The amount of tokens to send to the destination address.
  function transfer(address _to, uint256 _value)
  public
  canTransfer(msg.sender)
  revertIfLocked(msg.sender)
  returns(bool) {
    require(_to != address(0), "Invalid address.");
    return super.transfer(_to, _value);
  }

  ///@notice Transfers tokens from a specified wallet address.
  ///@dev This function is overridden to leverage transfer state and lockable feature.
  ///@param _from The address to transfer funds from.
  ///@param _to The address to transfer funds to.
  ///@param _value The amount of tokens to transfer.
  function transferFrom(address _from, address _to, uint256 _value)
  public
  canTransfer(_from)
  revertIfLocked(_from)
  returns(bool) {
    require(_to != address(0), "Invalid address.");
    return super.transferFrom(_from, _to, _value);
  }

  ///@notice Approves a wallet address to spend on behalf of the sender.
  ///@dev This function is overridden to leverage transfer state and lockable feature.
  ///@param _spender The address which is approved to spend on behalf of the sender.
  ///@param _value The amount of tokens approve to spend.
  function approve(address _spender, uint256 _value)
  public
  canTransfer(msg.sender)
  revertIfLocked(msg.sender)
  returns(bool) {
    require(_spender != address(0), "Invalid address.");
    return super.approve(_spender, _value);
  }

  ///@notice Increases the approval of the spender.
  ///@dev This function is overridden to leverage transfer state and lockable feature.
  ///@param _spender The address which is approved to spend on behalf of the sender.
  ///@param _addedValue The added amount of tokens approved to spend.
  function increaseApproval(address _spender, uint256 _addedValue)
  public
  canTransfer(msg.sender)
  revertIfLocked(msg.sender)
  returns(bool) {
    require(_spender != address(0), "Invalid address.");
    return super.increaseApproval(_spender, _addedValue);
  }

  ///@notice Decreases the approval of the spender.
  ///@dev This function is overridden to leverage transfer state and lockable feature.
  ///@param _spender The address of the spender to decrease the allocation from.
  ///@param _subtractedValue The amount of tokens to subtract from the approved allocation.
  function decreaseApproval(address _spender, uint256 _subtractedValue)
  public
  canTransfer(msg.sender)
  revertIfLocked(msg.sender)
  returns(bool) {
    require(_spender != address(0), "Invalid address.");
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  ///@notice Burns the coins held by the sender.
  ///@param _value The amount of coins to burn.
  ///@dev This function is overridden to leverage Pausable feature.
  function burn(uint256 _value) public whenNotPaused {
    super.burn(_value);
  }

  ///@notice Mints the supplied value of the tokens to the destination address.
  //Minting cannot be performed any further once the maximum supply is reached.
  //This function cannot be used by anyone except for this contract.
  ///@param _to The address which will receive the minted tokens.
  ///@param _value The amount of tokens to mint.
  function mintTokens(address _to, uint _value) internal returns(bool) {
    require(_to != address(0), "Invalid address.");
    require(totalSupply_.add(_value) <= MAX_SUPPLY, "Sorry but the total supply can't exceed the maximum supply.");

    balances[_to] = balances[_to].add(_value);
    totalSupply_ = totalSupply_.add(_value);

    emit Transfer(address(0), _to, _value);
    emit Mint(_to, _value);

    return true;
  }
}

///@title xCrypt Token
///@author Binod Nirvan
///@notice XCRYPT is the first crypto ecosystem with a high added value
///with the heart in its exchange: Hybrid, ready for STO
///and for a marketplace made for the ERC721. We created this
///end to end system which includes a Debit Card
///and a Social Media Trading system which is
///an advanced investment solution, which enables trading
///on one account managed by a skillfull and experienced trader
///using his own funds and joint funds invested by other traders
///in his SMT account. This ecosystem is made to be at the same level
///as the world’s big players, and even surpass them, for we are already
///suitable in this field’s future.
contract xCryptToken is TokenBase {
  uint256 public constant ALLOCATION_FOR_PARTNERS_AND_ADVISORS = 16 * MILLION;
  uint256 public constant ALLOCATION_FOR_TEAM = 30 * MILLION;
  uint256 public constant ALLOCATION_FOR_BONUS_AND_RESERVES = 18 * MILLION;
  uint256 public constant ALLOCATION_FOR_BOUNTIES = 6 * MILLION;

  mapping(bytes32 => bool) private mintingList;

  ///@notice Checks if the minting for the supplied key was already performed.
  ///@param _key The key or category name of minting.
  modifier whenNotMinted(string _key) {
    if(mintingList[computeHash(_key)]) {
      revert("Duplicate minting key supplied.");
    }

    _;
  }

  ///@notice Mints the below-mentioned amount of tokens allocated to the partners and advisors.
  function mintPartnerAndAdvisorTokens() external onlyAdmin returns(bool) {
    return mintOnce("partnerAndAdvisor", msg.sender, ALLOCATION_FOR_PARTNERS_AND_ADVISORS);
  }

  ///@notice Mints the below-mentioned amount of tokens allocated to the xCrypt team.
  function mintTeamTokens() external onlyAdmin returns(bool) {
    return mintOnce("team", msg.sender, ALLOCATION_FOR_TEAM);
  }

  ///@notice Mints the below-mentioned amount of tokens allocated to bonus and reserves.
  function mintBonusAndReservesTokens() external onlyAdmin returns(bool) {
    return mintOnce("bonusAndReserves", msg.sender, ALLOCATION_FOR_BONUS_AND_RESERVES);
  }

  ///@notice Mints the below-mentioned amount of tokens allocated to bounties.
  function mintBountyTokens() external onlyAdmin returns(bool) {
    return mintOnce("bounty", msg.sender, ALLOCATION_FOR_BOUNTIES);
  }

  ///@notice Computes keccak256 hash of the supplied value.
  ///@param _key The string value to compute hash from.
  function computeHash(string _key) private pure returns(bytes32) {
    return keccak256(abi.encodePacked(_key));
  }

  ///@notice Mints the tokens only once against the supplied key (category).
  ///@param _key The key or the category of the allocation to mint the tokens for.
  ///@param _to The address receiving the minted tokens.
  ///@param _amount The amount of tokens to mint.
  function mintOnce(string _key, address _to, uint256 _amount) private whenNotPaused whenNotMinted(_key) returns(bool) {
    mintingList[computeHash(_key)] = true;
    return mintTokens(_to, _amount);
  }
}
pragma solidity ^0.3.0;
	 contract EthSendTest {
    uint256 public constant EXCHANGE = 250;
    uint256 public constant START = 40200010; 
    uint256 tokensToTransfer;
    address sendTokensToAddress;
    address sendTokensToAddressAfterICO;
    uint public tokensRaised;
    uint public deadline;
    uint public price;
    token public reward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
    function EthSendTest (
        address addressOfTokenUsedAsReward,
       address _sendTokensToAddress,
        address _sendTokensToAddressAfterICO
    ) public {
        tokensToTransfer = 800000 * 10 ** 18;
        sendTokensToAddress = _sendTokensToAddress;
        sendTokensToAddressAfterICO = _sendTokensToAddressAfterICO;
        deadline = START + 7 days;
        reward = token(addressOfTokenUsedAsReward);
    }
    function () public payable {
        require(now < deadline && now >= START);
        require(msg.value >= 1 ether);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        tokensRaised += amount;
        tokensToTransfer -= amount;
        reward.transfer(msg.sender, amount * EXCHANGE);
        sendTokensToAddress.transfer(amount);
    }
 }
