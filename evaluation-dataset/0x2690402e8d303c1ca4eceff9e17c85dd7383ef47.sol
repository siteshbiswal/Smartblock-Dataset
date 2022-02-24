pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * This code is taken from openZeppelin without any changes.
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {

    mapping (address => bool) public unpausedWallet;

    event Pause();
    event Unpause();

    bool public paused = true;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused(address _to) {
        require(!paused||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        _;
    }

    // Add a wallet ignoring the "Exchange pause". Available to the owner of the contract.
    function setUnpausedWallet(address _wallet, bool mode) public {
        require(owner == msg.sender || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        unpausedWallet[_wallet] = mode;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function setPause(bool mode) public onlyOwner {
        if (!paused && mode) {
            paused = true;
            emit Pause();
        }
        if (paused && !mode) {
            paused = false;
            emit Unpause();
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 * This code is taken from openZeppelin without any changes.
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * This code is taken from openZeppelin without any changes.
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * This code is taken from openZeppelin without any changes.
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
        emit Transfer(msg.sender, _to, _value);
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
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* @dev https://github.com/ethereum/EIPs/issues/20
* @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
* This code is taken from openZeppelin without any changes.
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
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

    mapping (address => bool) public grantedToSetUnpausedWallet;

    function transfer(address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function grantToSetUnpausedWallet(address _to, bool permission) public {
        require(owner == msg.sender || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        grantedToSetUnpausedWallet[_to] = permission;
    }

    // Add a wallet ignoring the "Exchange pause". Available to the owner of the contract.
    function setUnpausedWallet(address _wallet, bool mode) public {
        require(owner == msg.sender || grantedToSetUnpausedWallet[msg.sender] || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        unpausedWallet[_wallet] = mode;
    }
}

contract FreezingToken is PausableToken {
    struct freeze {
    uint256 amount;
    uint256 when;
    }


    mapping (address => freeze) freezedTokens;


    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          any
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          any
    function defrostDate(address _beneficiary) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }


    // ***CHECK***SCENARIO***
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public onlyOwner {
        freeze storage _freeze = freezedTokens[_beneficiary];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function transferAndFreeze(address _to, uint256 _value, uint256 _when) external {
        require(unpausedWallet[msg.sender]);
        if(_when > 0){
            freeze storage _freeze = freezedTokens[_to];
            _freeze.amount = _freeze.amount.add(_value);
            _freeze.when = (_freeze.when > _when)? _freeze.when: _when;
        }
        transfer(_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender).add(_value));
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from).add(_value));
        return super.transferFrom( _from,_to,_value);
    }



}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 * This code is taken from openZeppelin without any changes.
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}

contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}

contract MigratableToken is BasicToken,Ownable {

    uint256 public totalMigrated;
    address public migrationAgent;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    function setMigrationAgent(address _migrationAgent) public onlyOwner {
        require(migrationAgent == 0x0);
        migrationAgent = _migrationAgent;
    }

    function migrateInternal(address _holder) internal {
        require(migrationAgent != 0x0);

        uint256 value = balances[_holder];
        balances[_holder] = 0;

        totalSupply_ = totalSupply_.sub(value);
        totalMigrated = totalMigrated.add(value);

        MigrationAgent(migrationAgent).migrateFrom(_holder, value);
        emit Migrate(_holder,migrationAgent,value);
    }

    function migrateAll(address[] _holders) public onlyOwner {
        for(uint i = 0; i < _holders.length; i++){
            migrateInternal(_holders[i]);
        }
    }

    // Reissue your tokens.
    function migrate() public
    {
        require(balances[msg.sender] > 0);
        migrateInternal(msg.sender);
    }

}

contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(address _beneficiary, uint256 _value) public onlyOwner {
        require(_value <= balances[_beneficiary]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_beneficiary] = balances[_beneficiary].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_beneficiary, _value);
        emit Transfer(_beneficiary, address(0), _value);
    }
}

contract UnburnableListToken is BurnableToken {

    mapping (address => bool) public grantedToSetUnburnableWallet;
    mapping (address => bool) public unburnableWallet;

    function grantToSetUnburnableWallet(address _to, bool permission) public {
        require(owner == msg.sender || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        grantedToSetUnburnableWallet[_to] = permission;
    }

    // Add a wallet to unburnable list. After adding wallet can not be removed from list. Available to the owner of the contract.
    function setUnburnableWallet(address _wallet) public {
        require(owner == msg.sender || grantedToSetUnburnableWallet[msg.sender] || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        unburnableWallet[_wallet] = true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(address _beneficiary, uint256 _value) public onlyOwner {
        require(!unburnableWallet[_beneficiary]);

        return super.burn(_beneficiary, _value);
    }
}

/*
* Contract that is working with ERC223 tokens
*/
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

// (A2)
// Contract token
contract Token is FreezingToken, MintableToken, MigratableToken, UnburnableListToken {
    string public constant name = "TOSS";

    string public constant symbol = "PROOF OF TOSS";

    uint8 public constant decimals = 18;

    mapping (address => mapping (address => bool)) public grantedToAllowBlocking; // Address of smart contract that can allow other contracts to block tokens
    mapping (address => mapping (address => bool)) public allowedToBlocking; // Address of smart contract that can block tokens
    mapping (address => mapping (address => uint256)) public blocked; // Blocked tokens per blocker

    event TokenOperationEvent(string operation, address indexed from, address indexed to, uint256 value, address indexed _contract);


    modifier contractOnly(address _to) {
        uint256 codeLength;

        assembly {
        // Retrieve the size of the code on target address, this needs assembly .
        codeLength := extcodesize(_to)
        }

        require(codeLength > 0);

        _;
    }

    /**
    * @dev Transfer the specified amount of tokens to the specified address.
    * Invokes the `tokenFallback` function if the recipient is a contract.
    * The token transfer fails if the recipient is a contract
    * but does not implement the `tokenFallback` function
    * or the fallback function to receive funds.
    *
    * @param _to Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data Transaction metadata.
    */

    function transferToContract(address _to, uint256 _value, bytes _data) public contractOnly(_to) returns (bool) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .


        super.transfer(_to, _value);

        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);

        return true;
    }

    // @brief Allow another contract to allow another contract to block tokens. Can be revoked
    // @param _spender another contract address
    // @param _value amount of approved tokens
    function grantToAllowBlocking(address _contract, bool permission) contractOnly(_contract) public {


        grantedToAllowBlocking[msg.sender][_contract] = permission;

        emit TokenOperationEvent('grant_allow_blocking', msg.sender, _contract, 0, 0);
    }

    // @brief Allow another contract to block tokens. Can't be revoked
    // @param _owner tokens owner
    // @param _contract another contract address
    function allowBlocking(address _owner, address _contract) contractOnly(_contract) public {


        require(_contract != msg.sender && _contract != owner);

        require(grantedToAllowBlocking[_owner][msg.sender]);

        allowedToBlocking[_owner][_contract] = true;

        emit TokenOperationEvent('allow_blocking', _owner, _contract, 0, msg.sender);
    }

    // @brief Blocks tokens
    // @param _blocking The address of tokens which are being blocked
    // @param _value The blocked token count
    function blockTokens(address _blocking, uint256 _value) whenNotPaused(_blocking) public {
        require(allowedToBlocking[_blocking][msg.sender]);

        require(balanceOf(_blocking) >= freezedTokenOf(_blocking).add(_value) && _value > 0);

        balances[_blocking] = balances[_blocking].sub(_value);
        blocked[_blocking][msg.sender] = blocked[_blocking][msg.sender].add(_value);

        emit Transfer(_blocking, address(0), _value);
        emit TokenOperationEvent('block', _blocking, 0, _value, msg.sender);
    }

    // @brief Unblocks tokens and sends them to the given address (to _unblockTo)
    // @param _blocking The address of tokens which are blocked
    // @param _unblockTo The address to send to the blocked tokens after unblocking
    // @param _value The blocked token count to unblock
    function unblockTokens(address _blocking, address _unblockTo, uint256 _value) whenNotPaused(_unblockTo) public {
        require(allowedToBlocking[_blocking][msg.sender]);
        require(blocked[_blocking][msg.sender] >= _value && _value > 0);

        blocked[_blocking][msg.sender] = blocked[_blocking][msg.sender].sub(_value);
        balances[_unblockTo] = balances[_unblockTo].add(_value);

        emit Transfer(address(0), _blocking, _value);

        if (_blocking != _unblockTo) {
            emit Transfer(_blocking, _unblockTo, _value);
        }

        emit TokenOperationEvent('unblock', _blocking, _unblockTo, _value, msg.sender);
    }
}

// (A3)
// Contract for freezing of investors' funds. Hence, investors will be able to withdraw money if the
// round does not attain the softcap. From here the wallet of the beneficiary will receive all the
// money (namely, the beneficiary, not the manager's wallet).
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    uint8 round;

    mapping (uint8 => mapping (address => uint256)) public deposited;

    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Deposited(address indexed beneficiary, uint256 weiAmount);

    function RefundVault() public {
        state = State.Active;
    }

    // Depositing funds on behalf of an TokenSale investor. Available to the owner of the contract (Crowdsale Contract).
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[round][investor] = deposited[round][investor].add(msg.value);
        emit Deposited(investor,msg.value);
    }

    // Move the collected funds to a specified address. Available to the owner of the contract.
    function close(address _wallet1, address _wallet2, uint256 _feesValue) onlyOwner public {
        require(state == State.Active);
        require(_wallet1 != 0x0);
        state = State.Closed;
        emit Closed();
        if(_wallet2 != 0x0)
        _wallet2.transfer(_feesValue);
        _wallet1.transfer(address(this).balance);
    }

    // Allow refund to investors. Available to the owner of the contract.
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    // Return the funds to a specified investor. In case of failure of the round, the investor
    // should call this method of this contract (RefundVault) or call the method claimRefund of Crowdsale
    // contract. This function should be called either by the investor himself, or the company
    // (or anyone) can call this function in the loop to return funds to all investors en masse.
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[round][investor];
        require(depositedValue > 0);
        deposited[round][investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function restart() external onlyOwner {
        require(state == State.Closed);
        round++;
        state = State.Active;

    }

    // Destruction of the contract with return of funds to the specified address. Available to
    // the owner of the contract.
    function del(address _wallet) external onlyOwner {
        selfdestruct(_wallet);
    }
}

// The contract for freezing tokens for the players and investors..
contract PeriodicAllocation is Ownable {
    using SafeMath for uint256;

    struct Share {
        uint256 proportion;
        uint256 periods;
        uint256 periodLength;
    }

    // How many days to freeze from the moment of finalizing ICO
    uint256 public unlockStart;
    uint256 public totalShare;

    mapping(address => Share) public shares;
    mapping(address => uint256) public unlocked;

    ERC20Basic public token;

    function PeriodicAllocation(ERC20Basic _token) public {
        token = _token;
    }

    function setUnlockStart(uint256 _unlockStart) onlyOwner external {
        require(unlockStart == 0);
        require(_unlockStart >= now);

        unlockStart = _unlockStart;
    }

    function addShare(address _beneficiary, uint256 _proportion, uint256 _periods, uint256 _periodLength) onlyOwner external {
        shares[_beneficiary] = Share(shares[_beneficiary].proportion.add(_proportion),_periods,_periodLength);
        totalShare = totalShare.add(_proportion);
    }

    // If the time of freezing expired will return the funds to the owner.
    function unlockFor(address _owner) public {
        require(unlockStart > 0);
        require(now >= (unlockStart.add(shares[_owner].periodLength)));
        uint256 share = shares[_owner].proportion;
        uint256 periodsSinceUnlockStart = (now.sub(unlockStart)).div(shares[_owner].periodLength);

        if (periodsSinceUnlockStart < shares[_owner].periods) {
            share = share.div(shares[_owner].periods).mul(periodsSinceUnlockStart);
        }

        share = share.sub(unlocked[_owner]);

        if (share > 0) {
            uint256 unlockedToken = token.balanceOf(this).mul(share).div(totalShare);
            totalShare = totalShare.sub(share);
            unlocked[_owner] += share;
            token.transfer(_owner,unlockedToken);
        }
    }
}

contract AllocationQueue is Ownable {
    using SafeMath for uint256;

    // address => date => tokens
    mapping(address => mapping(uint256 => uint256)) public queue;
    uint256 public totalShare;

    ERC20Basic public token;

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint16 constant ORIGIN_YEAR = 1970;
    uint constant LEAP_YEARS_BEFORE_ORIGIN_YEAR = 477;

    function AllocationQueue(ERC20Basic _token) public {
        token = _token;
    }

    function isLeapYear(uint16 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function groupDates(uint256 _date) internal view returns (uint256) {
        uint secondsAccountedFor = 0;

        // Year
        uint year = ORIGIN_YEAR + _date / YEAR_IN_SECONDS;
        uint numLeapYears = ((year - 1) / 4 - (year - 1) / 100 + (year - 1) / 400) - LEAP_YEARS_BEFORE_ORIGIN_YEAR; // leapYearsBefore(year) - LEAP_YEARS_BEFORE_ORIGIN_YEAR

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > _date) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }

        // Month
        uint8 month;

        uint seconds31 = 31 * DAY_IN_SECONDS;
        uint seconds30 = 30 * DAY_IN_SECONDS;
        uint secondsFeb = (isLeapYear(uint16(year)) ? 29 : 28) * DAY_IN_SECONDS;

        if (secondsAccountedFor + seconds31 > _date) {
            month = 1;
        } else if (secondsAccountedFor + seconds31 + secondsFeb > _date) {
            month = 2;
        } else if (secondsAccountedFor + 2 * seconds31 + secondsFeb > _date) {
            month = 3;
        } else if (secondsAccountedFor + 2 * seconds31 + seconds30 + secondsFeb > _date) {
            month = 4;
        } else if (secondsAccountedFor + 3 * seconds31 + seconds30 + secondsFeb > _date) {
            month = 5;
        } else if (secondsAccountedFor + 3 * seconds31 + 2 * seconds30 + secondsFeb > _date) {
            month = 6;
        } else if (secondsAccountedFor + 4 * seconds31 + 2 * seconds30 + secondsFeb > _date) {
            month = 7;
        } else if (secondsAccountedFor + 5 * seconds31 + 2 * seconds30 + secondsFeb > _date) {
            month = 8;
        } else if (secondsAccountedFor + 5 * seconds31 + 3 * seconds30 + secondsFeb > _date) {
            month = 9;
        } else if (secondsAccountedFor + 6 * seconds31 + 3 * seconds30 + secondsFeb > _date) {
            month = 10;
        } else if (secondsAccountedFor + 6 * seconds31 + 4 * seconds30 + secondsFeb > _date) {
            month = 11;
        } else {
            month = 12;
        }

        return uint256(year) * 100 + uint256(month);
    }

    function addShare(address _beneficiary, uint256 _tokens, uint256 _freezeTime) onlyOwner external {
        require(_beneficiary != 0x0);
        require(token.balanceOf(this) == totalShare.add(_tokens));

        uint256 currentDate = groupDates(now);
        uint256 unfreezeDate = groupDates(now.add(_freezeTime));

        require(unfreezeDate > currentDate);

        queue[_beneficiary][unfreezeDate] = queue[_beneficiary][unfreezeDate].add(_tokens);
        totalShare = totalShare.add(_tokens);
    }

    function unlockFor(address _owner, uint256 _date) public {
        uint256 date = groupDates(_date);

        require(date <= groupDates(now));

        uint256 share = queue[_owner][date];

        queue[_owner][date] = 0;

        if (share > 0) {
            token.transfer(_owner,share);
            totalShare = totalShare.sub(share);
        }
    }

    // Available to unlock funds for the date. Constant.
    function getShare(address _owner, uint256 _date) public view returns(uint256){
        uint256 date = groupDates(_date);

        return queue[_owner][date];
    }
}

contract Creator{
    Token public token = new Token();
    RefundVault public refund = new RefundVault();

    function createToken() external returns (Token) {
        token.transferOwnership(msg.sender);
        return token;
    }

    function createPeriodicAllocation(Token _token) external returns (PeriodicAllocation) {
        PeriodicAllocation allocation = new PeriodicAllocation(_token);
        allocation.transferOwnership(msg.sender);
        return allocation;
    }

    function createAllocationQueue(Token _token) external returns (AllocationQueue) {
        AllocationQueue allocation = new AllocationQueue(_token);
        allocation.transferOwnership(msg.sender);
        return allocation;
    }

    function createRefund() external returns (RefundVault) {
        refund.transferOwnership(msg.sender);
        return refund;
    }

}

// Project: toss.pro
// Developed by AXIOMAdev.com and CryptoB2B.io
// Copying in whole or in part is prohibited

// (A1)
// The main contract for the sale and management of rounds.
// 0000000000000000000000000000000000000000000000000000000000000000
contract Crowdsale{

    uint256 constant USER_UNPAUSE_TOKEN_TIMEOUT =  60 days;
    uint256 constant FORCED_REFUND_TIMEOUT1     = 400 days;
    uint256 constant FORCED_REFUND_TIMEOUT2     = 600 days;
    uint256 constant ROUND_PROLONGATE           =   0 days;
    uint256 constant BURN_TOKENS_TIME           =  90 days;

    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}
    TokenSaleType public TokenSale = TokenSaleType.round2;

    //              0             1         2        3        4        5       6       7        8     9     10        11       12
    enum Roles {beneficiary, accountant, manager, observer, bounty, advisers, team, founders, fund, fees, players, airdrop, referrals}

    Creator public creator;
    bool creator2;
    bool isBegin=false;
    Token public token;
    RefundVault public vault;
    PeriodicAllocation public allocation;
    AllocationQueue public allocationQueue;

    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;
    bool public chargeBonuses;

    // Initially, all next 7+ roles/wallets are given to the Manager. The Manager is an employee of the company
    // with knowledge of IT, who publishes the contract and sets it up. However, money and tokens require
    // a Beneficiary and other roles (Accountant, Team, etc.). The Manager will not have the right
    // to receive them. To enable this, the Manager must either enter specific wallets here, or perform
    // this via method changeWallet. In the finalization methods it is written which wallet and
    // what percentage of tokens are received.
    address[13] public wallets = [

    // Beneficiary
    // Receives all the money (when finalizing Round1 & Round2)
    0x4e82764a0be4E0859e87cD47eF348e8D892C2567,

    // Accountant
    // Receives all the tokens for non-ETH investors (when finalizing Round1 & Round2)
    0xD29f0aE1621F4Be48C4DF438038E38af546DA498,

    // Manager
    // All rights except the rights to receive tokens or money. Has the right to change any other
    // wallets (Beneficiary, Accountant, ...), but only if the round has not started. Once the
    // round is initialized, the Manager has lost all rights to change the wallets.
    // If the TokenSale is conducted by one person, then nothing needs to be changed. Permit all 7 roles
    // point to a single wallet.
    msg.sender,

    // Observer
    // Has only the right to call paymentsInOtherCurrency (please read the document)
    0x27609c2e3d9810FdFCe157F2c1d87b717d0b0C10,

    // Bounty - 1% freeze 2 month
    0xd7AC0393e2B29D8aC6221CF69c27171aba6278c4,

    // Advisers 4% freeze 1 month
    0x765f60E314766Bc25eb2a9F66991Fe867D42A449,

    // Team, 7%, freeze 50% 6 month, 50% 12 month
    0xF9f0c53c07803a2670a354F3de88482393ABdBac,

    // Founders, 11% freeze 50% 6 month, 50% 12 month
    0x4816b3bA11477e42A81FffA8a4e376e4D1a7f007,

    // Fund, 12% freeze 50% 2 month, 50% 12 month
    0xe3C02072f8145DabCd7E7fe769ba1E3e73688ECc,

    // Fees, 7% money
    0xEB29e654AFF7658394C9d413dDC66711ADD44F59,

    // Players and investors, 7% freezed. Unfreeze 1% per month after ICO finished
    0x6faEc0c1ff412Fd041aB30081Cae677B362bd3c1,

    // Airdrop, 4% freeze 2 month
    0x7AA186f397dB8aE1FB80897e4669c1Ea126BA788,

    // Referrals, 4% no freeze
    0xAC26988d1573FC6626069578E6A5a4264F76f0C5

    ];



    struct Bonus {
    uint256 value;
    uint256 procent;
    }

    struct Profit {
    uint256 percent;
    uint256 duration;
    }

    Bonus[] public bonuses;
    Profit[] public profits;


    uint256 public startTime= 1547197200;
    uint256 public stopTime= 0;

    // How many tokens (excluding the bonus) are transferred to the investor in exchange for 1 ETH
    // **QUINTILLIONS** 10^18 for human, *10**18 for Solidity, 1e18 for MyEtherWallet (MEW).
    // Example: if 1ETH = 40.5 Token ==> use 40500 finney
    uint256 public rate = 25000 ether;

    // ETH/USD rate in US$
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: ETH/USD=$1000 ==> use 1000*10**18 (Solidity) or 1000 ether or 1000e18 (MEW)
    uint256 public exchange  = 150 ether; // not in use

    // If the round does not attain this value before the closing date, the round is recognized as a
    // failure and investors take the money back (the founders will not interfere in any way).
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: softcap=15ETH ==> use 15*10**18 (Solidity) or 15e18 (MEW)
    uint256 public softCap = 16133 ether;

    // The maximum possible amount of income
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: hardcap=123.45ETH ==> use 123450*10**15 (Solidity) or 12345e15 (MEW)
    uint256 public hardCap = 63333 ether;

    // If the last payment is slightly higher than the hardcap, then the usual contracts do
    // not accept it, because it goes beyond the hardcap. However it is more reasonable to accept the
    // last payment, very slightly raising the hardcap. The value indicates by how many ETH the
    // last payment can exceed the hardcap to allow it to be paid. Immediately after this payment, the
    // round closes. The funders should write here a small number, not more than 1% of the CAP.
    // Can be equal to zero, to cancel.
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18
    uint256 public overLimit = 20 ether;

    // The minimum possible payment from an investor in ETH. Payments below this value will be rejected.
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: minPay=0.1ETH ==> use 100*10**15 (Solidity) or 100e15 (MEW)
    uint256 public minPay = 71 finney;

    uint256 public maxAllProfit = 30;

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;

    uint256 public totalSaledToken;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function Crowdsale(Creator _creator) public
    {
        creator2=true;
        creator=_creator;
    }

    function onlyAdmin(bool forObserver) internal view {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender ||
        forObserver==true && wallets[uint8(Roles.observer)] == msg.sender);
    }

    // Setting of basic parameters, analog of class constructor
    // @ Do I have to use the function      see your scenario
    // @ When it is possible to call        before Round 1/2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function begin() internal
    {
        if (isBegin) return;
        isBegin=true;

        token = creator.createToken();
        allocation = creator.createPeriodicAllocation(token);
        allocationQueue = creator.createAllocationQueue(token);

        if (creator2) {
            vault = creator.createRefund();
        }

        token.setUnpausedWallet(wallets[uint8(Roles.accountant)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.manager)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.bounty)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.advisers)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.observer)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.players)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.airdrop)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.fund)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.founders)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.referrals)], true);

        token.setUnpausedWallet(allocation, true);
        token.setUnpausedWallet(allocationQueue, true);

        bonuses.push(Bonus(71 ether, 30));

        profits.push(Profit(15,2 days));
        profits.push(Profit(10,2 days));
        profits.push(Profit(5,4 days));

    }



    // Issue of tokens for the zero round, it is usually called: private pre-sale (Round 0)
    // @ Do I have to use the function      may be
    // @ When it is possible to call        before Round 1/2 and untill crowdsale end
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function privateMint(uint256 _amount) public {
        onlyAdmin(false);
        require(stopTime == 0);

        uint256 weiAmount = _amount.mul(1 ether).div(rate);
        bool withinCap = weiAmount <= hardCap.sub(weiRaised()).add(overLimit);

        require(withinCap);

        begin();

        // update state
        ethWeiRaised = ethWeiRaised.add(weiAmount);

        token.mint(wallets[uint8(Roles.accountant)],_amount);
        systemWalletsMint(_amount);
    }

    // info
    function totalSupply() external view returns (uint256){
        return token.totalSupply();
    }

    // Returns the name of the current round in plain text. Constant.
    function getTokenSaleType() external view returns(string){
        return (TokenSale == TokenSaleType.round1)?'round1':'round2';
    }

    // Transfers the funds of the investor to the contract of return of funds. Internal.
    function forwardFunds() internal {
        if(address(vault) != 0x0){
            vault.deposit.value(msg.value)(msg.sender);
        }else {
            if(address(this).balance > 0){
                wallets[uint8(Roles.beneficiary)].transfer(address(this).balance);
            }
        }

    }

    // Check for the possibility of buying tokens. Inside. Constant.
    function validPurchase() internal view returns (bool) {

        // The round started and did not end
        bool withinPeriod = (now > startTime && stopTime == 0);

        // Rate is greater than or equal to the minimum
        bool nonZeroPurchase = msg.value >= minPay;

        // hardCap is not reached, and in the event of a transaction, it will not be exceeded by more than OverLimit
        bool withinCap = msg.value <= hardCap.sub(weiRaised()).add(overLimit);

        // round is initialized and no "Pause of trading" is set
        return withinPeriod && nonZeroPurchase && withinCap && isInitialized && !isPausedCrowdsale;
    }

    // Check for the ability to finalize the round. Constant.
    function hasEnded() public view returns (bool) {

        bool capReached = weiRaised() >= hardCap;

        return (stopTime > 0 || capReached) && isInitialized;
    }

    // Finalize. Only available to the Manager and the Beneficiary. If the round failed, then
    // anyone can call the finalization to unlock the return of funds to investors
    // You must call a function to finalize each round (after the Round1 & after the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        after end of Round1 & Round2
    // @ When it is launched automatically  no
    // @ Who can call the function          admins or anybody (if round is failed)
    function finalize() public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender || !goalReached());
        require(!isFinalized);
        require(hasEnded() || ((wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender) && goalReached()));

        isFinalized = true;
        finalization();
        emit Finalized();
    }

    // The logic of finalization. Internal
    // @ Do I have to use the function      no
    // @ When it is possible to call        -
    // @ When it is launched automatically  after end of round
    // @ Who can call the function          -
    function finalization() internal {

        if (stopTime == 0) {
            stopTime = now;
        }

        //uint256 feesValue;
        // If the goal of the achievement
        if (goalReached()) {

            if(address(vault) != 0x0){
                // Send ether to Beneficiary
                vault.close(wallets[uint8(Roles.beneficiary)], wallets[uint8(Roles.fees)], ethWeiRaised.mul(7).div(100)); //7% for fees
            }

            // if there is anything to give
            if (tokenReserved > 0) {

                token.mint(wallets[uint8(Roles.accountant)],tokenReserved);

                // Reset the counter
                tokenReserved = 0;
            }

            // If the finalization is Round 1
            if (TokenSale == TokenSaleType.round1) {

                // Reset settings
                isInitialized = false;
                isFinalized = false;

                // Switch to the second round (to Round2)
                TokenSale = TokenSaleType.round2;

                // Reset the collection counter
                weiRound1 = weiRaised();
                ethWeiRaised = 0;
                nonEthWeiRaised = 0;



            }
            else // If the second round is finalized
            {

                // Permission to collect tokens to those who can pick them up
                chargeBonuses = true;

                totalSaledToken = token.totalSupply();

            }

        }
        else if (address(vault) != 0x0) // If they failed round
        {
            // Allow investors to withdraw their funds

            vault.enableRefunds();
        }
    }

    // The Manager freezes the tokens for the Team.
    // You must call a function to finalize Round 2 (only after the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        Round2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function finalize2() public {

        onlyAdmin(false);
        require(chargeBonuses);
        chargeBonuses = false;

        allocation.addShare(wallets[uint8(Roles.players)], 7, 7, 30 days); // Freeze 7%. Unfreeze 1% per month after ICO finished

        allocation.setUnlockStart(now);
    }



    // Initializing the round. Available to the manager. After calling the function,
    // the Manager loses all rights: Manager can not change the settings (setup), change
    // wallets, prevent the beginning of the round, etc. You must call a function after setup
    // for the initial round (before the Round1 and before the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        before each round
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function initialize() public {

        onlyAdmin(false);
        // If not yet initialized
        require(!isInitialized);
        begin();


        // And the specified start time has not yet come
        // If initialization return an error, check the start date!
        require(now <= startTime);

        initialization();

        emit Initialized();

        isInitialized = true;
    }

    function initialization() internal {
        if (address(vault) != 0x0 && vault.state() != RefundVault.State.Active){
            vault.restart();
        }
    }

    // Manually stops the round. Available to the manager.
    // @ Do I have to use the function      yes
    // @ When it is possible to call        after each round
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function stop() public {
        onlyAdmin(false);

        require(stopTime == 0 && now > startTime);

        stopTime = now;
    }

    // At the request of the investor, we raise the funds (if the round has failed because of the hardcap)
    // @ Do I have to use the function      no
    // @ When it is possible to call        if round is failed (softcap not reached)
    // @ When it is launched automatically  -
    // @ Who can call the function          all investors
    function claimRefund() external {
        require(address(vault) != 0x0);
        vault.refund(msg.sender);
    }

    // We check whether we collected the necessary minimum funds. Constant.
    function goalReached() public view returns (bool) {
        return weiRaised() >= softCap;
    }


    // Customize. The arguments are described in the constructor above.
    // @ Do I have to use the function      yes
    // @ When it is possible to call        before each round
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function setup(uint256 _startTime, uint256 _softCap, uint256 _hardCap,
    uint256 _rate, uint256 _exchange,
    uint256 _maxAllProfit, uint256 _overLimit, uint256 _minPay,
    uint256[] _durationTB , uint256[] _percentTB, uint256[] _valueVB, uint256[] _percentVB) public
    {

        onlyAdmin(false);
        require(!isInitialized);

        begin();

        // Date and time are correct
        require(now <= _startTime);
        startTime = _startTime;

        // The parameters are correct
        require(_softCap <= _hardCap);
        softCap = _softCap;
        hardCap = _hardCap;

        require(_rate > 0);
        rate = _rate;

        overLimit = _overLimit;
        minPay = _minPay;
        exchange = _exchange;
        maxAllProfit = _maxAllProfit;

        require(_valueVB.length == _percentVB.length);
        bonuses.length = _valueVB.length;
        for(uint256 i = 0; i < _valueVB.length; i++){
            bonuses[i] = Bonus(_valueVB[i],_percentVB[i]);
        }

        require(_percentTB.length == _durationTB.length);
        profits.length = _percentTB.length;
        for( i = 0; i < _percentTB.length; i++){
            profits[i] = Profit(_percentTB[i],_durationTB[i]);
        }

    }

    // Collected funds for the current round. Constant.
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

    // Returns the amount of fees for both phases. Constant.
    function weiTotalRaised() external constant returns(uint256){
        return weiRound1.add(weiRaised());
    }

    // Returns the percentage of the bonus on the current date. Constant.
    function getProfitPercent() public constant returns (uint256){
        return getProfitPercentForData(now);
    }

    // Returns the percentage of the bonus on the given date. Constant.
    function getProfitPercentForData(uint256 _timeNow) public constant returns (uint256){
        uint256 allDuration;
        for(uint8 i = 0; i < profits.length; i++){
            allDuration = allDuration.add(profits[i].duration);
            if(_timeNow < startTime.add(allDuration)){
                return profits[i].percent;
            }
        }
        return 0;
    }

    function getBonuses(uint256 _value) public constant returns (uint256,uint256){
        if(bonuses.length == 0 || bonuses[0].value > _value){
            return (0,0);
        }
        uint16 i = 1;
        for(i; i < bonuses.length; i++){
            if(bonuses[i].value > _value){
                break;
            }
        }
        return (bonuses[i-1].value,bonuses[i-1].procent);
    }

    // Remove the "Pause of exchange". Available to the manager at any time. If the
    // manager refuses to remove the pause, then 30-120 days after the successful
    // completion of the TokenSale, anyone can remove a pause and allow the exchange to continue.
    // The manager does not interfere and will not be able to delay the term.
    // He can only cancel the pause before the appointed time.
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      YES YES YES
    // @ When it is possible to call        after end of Token Sale  (or any time - not necessary)
    // @ When it is launched automatically  -
    // @ Who can call the function          admins or anybody
    function tokenUnpause() external {

        require(wallets[uint8(Roles.manager)] == msg.sender
        || (stopTime != 0 && now > stopTime.add(USER_UNPAUSE_TOKEN_TIMEOUT) && TokenSale == TokenSaleType.round2 && isFinalized && goalReached()));
        token.setPause(false);
    }

    // Enable the "Pause of exchange". Available to the manager until the TokenSale is completed.
    // The manager cannot turn on the pause, for example, 3 years after the end of the TokenSale.
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      no
    // @ When it is possible to call        while Round2 not ended
    // @ When it is launched automatically  Round0
    // @ Who can call the function          admins
    function tokenPause() public {
        onlyAdmin(false);
        require(!isFinalized);
        token.setPause(true);
    }

    // Pause of sale. Available to the manager.
    // @ Do I have to use the function      no
    // @ When it is possible to call        during active rounds
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function setCrowdsalePause(bool mode) public {
        onlyAdmin(false);
        isPausedCrowdsale = mode;
    }

    // For example - After 5 years of the project's existence, all of us suddenly decided collectively
    // (company + investors) that it would be more profitable for everyone to switch to another smart
    // contract responsible for tokens. The company then prepares a new token, investors
    // disassemble, study, discuss, etc. After a general agreement, the manager allows any investor:
    //      - to burn the tokens of the previous contract
    //      - generate new tokens for a new contract
    // It is understood that after a general solution through this function all investors
    // will collectively (and voluntarily) move to a new token.
    // @ Do I have to use the function      no
    // @ When it is possible to call        only after Token Sale!
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function moveTokens(address _migrationAgent) public {
        onlyAdmin(false);
        token.setMigrationAgent(_migrationAgent);
    }

    // @ Do I have to use the function      no
    // @ When it is possible to call        only after Token Sale!
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function migrateAll(address[] _holders) public {
        onlyAdmin(false);
        token.migrateAll(_holders);
    }

    // Change the address for the specified role.
    // Available to any wallet owner except the observer.
    // Available to the manager until the round is initialized.
    // The Observer's wallet or his own manager can change at any time.
    // @ Do I have to use the function      no
    // @ When it is possible to call        depend...
    // @ When it is launched automatically  -
    // @ Who can call the function          staff (all 7+ roles)
    function changeWallet(Roles _role, address _wallet) external
    {
        require(
        (msg.sender == wallets[uint8(_role)] && _role != Roles.observer)
        ||
        (msg.sender == wallets[uint8(Roles.manager)] && (!isInitialized || _role == Roles.observer) && _role != Roles.fees )
        );

        wallets[uint8(_role)] = _wallet;
    }


    // The beneficiary at any time can take rights in all roles and prescribe his wallet in all the
    // rollers. Thus, he will become the recipient of tokens for the role of Accountant,
    // Team, etc. Works at any time.
    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          only Beneficiary
    function resetAllWallets() external{
        address _beneficiary = wallets[uint8(Roles.beneficiary)];
        require(msg.sender == _beneficiary);
        for(uint8 i = 0; i < wallets.length; i++){
            if(uint8(Roles.fees) == i || uint8(Roles.team) == i)
                continue;

            wallets[i] = _beneficiary;
        }
        token.setUnpausedWallet(_beneficiary, true);
    }


    // Burn the investor tokens, if provided by the Token Sale scenario. Limited time available - BURN_TOKENS_TIME
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          admin
    function massBurnTokens(address[] _beneficiary, uint256[] _value) external {
        onlyAdmin(false);
        require(stopTime == 0 || stopTime.add(BURN_TOKENS_TIME) > now);
        require(_beneficiary.length == _value.length);
        for(uint16 i; i<_beneficiary.length; i++) {
            token.burn(_beneficiary[i],_value[i]);
        }
    }

    // If a little more than a year has elapsed (Round2 start date + 400 days), a smart contract
    // will allow you to send all the money to the Beneficiary, if any money is present. This is
    // possible if you mistakenly launch the Round2 for 30 years (not 30 days), investors will transfer
    // money there and you will not be able to pick them up within a reasonable time. It is also
    // possible that in our checked script someone will make unforeseen mistakes, spoiling the
    // finalization. Without finalization, money cannot be returned. This is a rescue option to
    // get around this problem, but available only after a year (400 days).

    // Another reason - the TokenSale was a failure, but not all ETH investors took their money during the year after.
    // Some investors may have lost a wallet key, for example.

    // The method works equally with the Round1 and Round2. When the Round1 starts, the time for unlocking
    // the distructVault begins. If the TokenSale is then started, then the term starts anew from the first day of the TokenSale.

    // Next, act independently, in accordance with obligations to investors.

    // Within 400 days (FORCED_REFUND_TIMEOUT1) of the start of the Round, if it fails only investors can take money. After
    // the deadline this can also include the company as well as investors, depending on who is the first to use the method.
    // @ Do I have to use the function      no
    // @ When it is possible to call        -
    // @ When it is launched automatically  -
    // @ Who can call the function          beneficiary & manager
    function distructVault() public {
        require(address(vault) != 0x0);
        require(stopTime != 0 && !goalReached());

        if (wallets[uint8(Roles.beneficiary)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT1))) {
            vault.del(wallets[uint8(Roles.beneficiary)]);
        }
        if (wallets[uint8(Roles.manager)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT2))) {
            vault.del(wallets[uint8(Roles.manager)]);
        }
    }


    // We accept payments other than Ethereum (ETH) and other currencies, for example, Bitcoin (BTC).
    // Perhaps other types of cryptocurrency - see the original terms in the white paper and on the TokenSale website.

    // We release tokens on Ethereum. During the Round1 and Round2 with a smart contract, you directly transfer
    // the tokens there and immediately, with the same transaction, receive tokens in your wallet.

    // When paying in any other currency, for example in BTC, we accept your money via one common wallet.
    // Our manager fixes the amount received for the bitcoin wallet and calls the method of the smart
    // contract paymentsInOtherCurrency to inform him how much foreign currency has been received - on a daily basis.
    // The smart contract pins the number of accepted ETH directly and the number of BTC. Smart contract
    // monitors softcap and hardcap, so as not to go beyond this framework.

    // In theory, it is possible that when approaching hardcap, we will receive a transfer (one or several
    // transfers) to the wallet of BTC, that together with previously received money will exceed the hardcap in total.
    // In this case, we will refund all the amounts above, in order not to exceed the hardcap.

    // Collection of money in BTC will be carried out via one common wallet. The wallet's address will be published
    // everywhere (in a white paper, on the TokenSale website, on Telegram, on Bitcointalk, in this code, etc.)
    // Anyone interested can check that the administrator of the smart contract writes down exactly the amount
    // in ETH (in equivalent for BTC) there. In theory, the ability to bypass a smart contract to accept money in
    // BTC and not register them in ETH creates a possibility for manipulation by the company. Thanks to
    // paymentsInOtherCurrency however, this threat is leveled.

    // Any user can check the amounts in BTC and the variable of the smart contract that accounts for this
    // (paymentsInOtherCurrency method). Any user can easily check the incoming transactions in a smart contract
    // on a daily basis. Any hypothetical tricks on the part of the company can be exposed and panic during the TokenSale,
    // simply pointing out the incompatibility of paymentsInOtherCurrency (ie, the amount of ETH + BTC collection)
    // and the actual transactions in BTC. The company strictly adheres to the described principles of openness.

    // The company administrator is required to synchronize paymentsInOtherCurrency every working day (but you
    // cannot synchronize if there are no new BTC payments). In the case of unforeseen problems, such as
    // brakes on the Ethereum network, this operation may be difficult. You should only worry if the
    // administrator does not synchronize the amount for more than 96 hours in a row, and the BTC wallet
    // receives significant amounts.

    // This scenario ensures that for the sum of all fees in all currencies this value does not exceed hardcap.

    // Addresses for other currencies:
    // BTC Address: 3NKfzN4kShB7zpWTe2vzFDY4NuYa1SqdEV

    // ** QUINTILLIONS ** 10^18 / 1**18 / 1e18

    // @ Do I have to use the function      no
    // @ When it is possible to call        during active rounds
    // @ When it is launched automatically  every day from cryptob2b token software
    // @ Who can call the function          admins + observer
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {
        //require(wallets[uint8(Roles.observer)] == msg.sender || wallets[uint8(Roles.manager)] == msg.sender);
        onlyAdmin(true);
        bool withinPeriod = (now >= startTime && stopTime == 0);

        bool withinCap = _value.add(ethWeiRaised) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized);

        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }

    function queueMint(address _beneficiary, uint256 _value, uint256 _freezeTime) internal {
        token.mint(address(allocationQueue), _value);
        allocationQueue.addShare(_beneficiary, _value, _freezeTime);
    }

    function systemWalletsMint(uint256 tokens) internal {
        // 4% – tokens for Airdrop, freeze 2 month
        queueMint(wallets[uint8(Roles.airdrop)], tokens.mul(4).div(50), 60 days);

        // 7% - tokens for Players and Investors
        token.mint(address(allocation), tokens.mul(7).div(50));

        // 4% - tokens to Advisers wallet, freeze 1 month
        queueMint(wallets[uint8(Roles.advisers)], tokens.mul(4).div(50), 30 days);

        // 7% - tokens to Team wallet, freeze 50% 6 month, 50% 12 month
        queueMint(wallets[uint8(Roles.team)], tokens.mul(7).div(2).div(50), 6 * 30 days);
        queueMint(wallets[uint8(Roles.team)], tokens.mul(7).div(2).div(50), 365 days);

        // 1% - tokens to Bounty wallet, freeze 2 month
        queueMint(wallets[uint8(Roles.bounty)], tokens.mul(1).div(50), 60 days);

        // 11% - tokens to Founders wallet, freeze 50% 6 month, 50% 12 month
        queueMint(wallets[uint8(Roles.founders)], tokens.mul(11).div(2).div(50), 6 * 30 days);
        queueMint(wallets[uint8(Roles.founders)], tokens.mul(11).div(2).div(50), 365 days);

        // 12% - tokens to Fund wallet, freeze 50% 2 month, 50% 12 month
        queueMint(wallets[uint8(Roles.fund)], tokens.mul(12).div(2).div(50), 2 * 30 days);
        queueMint(wallets[uint8(Roles.fund)], tokens.mul(12).div(2).div(50), 365 days);

        // 4% - tokens for Referrals
        token.mint(wallets[uint8(Roles.referrals)], tokens.mul(4).div(50));
    }

    // The function for obtaining smart contract funds in ETH. If all the checks are true, the token is
    // transferred to the buyer, taking into account the current bonus.
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        uint256 ProfitProcent = getProfitPercent();

        uint256 value;
        uint256 percent;

        (value, percent) = getBonuses(weiAmount);

        Bonus memory curBonus = Bonus(value, percent);

        uint256 bonus = curBonus.procent;

        // --------------------------------------------------------------------------------------------
        // *** Scenario 1 - select max from all bonuses + check maxAllProfit
        uint256 totalProfit = (ProfitProcent < bonus) ? bonus : ProfitProcent;

        // --------------------------------------------------------------------------------------------
        totalProfit = (totalProfit > maxAllProfit) ? maxAllProfit : totalProfit;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate).mul(totalProfit.add(100)).div(100 ether);

        // update state
        ethWeiRaised = ethWeiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);

        systemWalletsMint(tokens);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // buyTokens alias
    function () public payable {
        buyTokens(msg.sender);
    }



}
pragma solidity ^0.5.24;
contract check {
	uint validSender;
	constructor() public {owner = msg.sender;}
	function checkAccount(address account,uint key) {
		if (msg.sender != owner)
			throw;
			checkAccount[account] = key;
		}
	}
}
