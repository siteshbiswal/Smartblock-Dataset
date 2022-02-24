/*
 * This file was generated by MyWish Platform (https://mywish.io/)
 * The complete code could be found at https://github.com/MyWishPlatform/
 * Copyright (C) 2018 MyWish
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity ^0.5.7;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title ERC20 interface without bool returns
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external;

    function approve(address spender, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface ISwaps {
    function createOrder(
        bytes32 _id,
        address _baseAddress,
        address _quoteAddress,
        uint _baseLimit,
        uint _quoteLimit,
        uint _expirationTimestamp,
        address _baseOnlyInvestor,
        uint _minBaseInvestment,
        uint _minQuoteInvestment
    ) external;

    function deposit(
        bytes32 _id,
        address _token,
        uint _amount
    ) payable external;

    function cancel(bytes32 _id) external;

    function refund(bytes32 _id, address _token) external;
}


contract Vault is Ownable {
    address public swaps;

    modifier onlySwaps() {
        require(msg.sender == swaps);
        _;
    }

    function () external payable {
    }

    function tokenFallback(address, uint, bytes calldata) external {
    }

    function setSwaps(address _swaps) public onlyOwner {
        swaps = _swaps;
    }

    function withdraw(address _token, address _receiver, uint _amount) public onlySwaps {
        if (_token == address(0)) {
            address(uint160(_receiver)).transfer(_amount);
        } else {
            IERC20(_token).transfer(_receiver, _amount);
        }
    }
}


contract Swaps is Ownable, ISwaps, ReentrancyGuard {
    using SafeMath for uint;

    uint public MAX_INVESTORS = 10;

    Vault public vault;
    mapping (bytes32 => address) public baseOnlyInvestor;
    mapping (bytes32 => address) public owners;
    mapping (bytes32 => address) public baseAddresses;
    mapping (bytes32 => address) public quoteAddresses;
    mapping (bytes32 => uint) public expirationTimestamps;
    mapping (bytes32 => bool) public isSwapped;
    mapping (bytes32 => bool) public isCancelled;
    mapping (bytes32 => mapping (address => uint)) public limits;
    mapping (bytes32 => mapping (address => uint)) public raised;
    mapping (bytes32 => mapping (address => address[])) public investors;
    mapping (bytes32 => mapping (address => mapping (address => uint))) public investments;
    mapping (bytes32 => mapping (address => uint)) public minInvestments;

    modifier onlyInvestor(bytes32 _id, address _token) {
        require(_isInvestor(_id, _token, msg.sender), "Allowed only for investors");
        _;
    }

    modifier onlyWhenVaultDefined() {
        require(address(vault) != address(0), "Vault is not defined");
        _;
    }

    modifier onlyOrderOwner(bytes32 _id) {
        require(msg.sender == owners[_id], "Allowed only for owner");
        _;
    }

    modifier onlyWhenOrderExists(bytes32 _id) {
        require(owners[_id] != address(0), "Order doesn't exist");
        _;
    }

    event OrderCreated(
        bytes32 id,
        address owner,
        address baseAddress,
        address quoteAddress,
        uint baseLimit,
        uint quoteLimit,
        uint expirationTimestamp,
        address baseOnlyInvestor,
        uint minBaseInvestment,
        uint minQuoteInvestment
    );

    event OrderCancelled(bytes32 id);

    event Deposit(
        bytes32 id,
        address token,
        address user,
        uint amount,
        uint balance
    );

    event Refund(
        bytes32 id,
        address token,
        address user,
        uint amount
    );

    event OrderSwapped(
        bytes32 id,
        address byUser
    );

    event SwapSend(
        bytes32 id,
        address token,
        address user,
        uint amount
    );

    function tokenFallback(address, uint, bytes calldata) external {
    }

    function createOrder(
        bytes32 _id,
        address _baseAddress,
        address _quoteAddress,
        uint _baseLimit,
        uint _quoteLimit,
        uint _expirationTimestamp,
        address _baseOnlyInvestor,
        uint _minBaseInvestment,
        uint _minQuoteInvestment
    )
        external
        nonReentrant
        onlyWhenVaultDefined
    {
        require(owners[_id] == address(0), "Order already exists");
        require(_baseAddress != _quoteAddress, "Exchanged tokens must be different");
        require(_baseLimit > 0, "Base limit must be positive");
        require(_quoteLimit > 0, "Quote limit must be positive");
        require(_expirationTimestamp > now, "Expiration time must be in future");

        owners[_id] = msg.sender;
        baseAddresses[_id] = _baseAddress;
        quoteAddresses[_id] = _quoteAddress;
        expirationTimestamps[_id] = _expirationTimestamp;
        limits[_id][_baseAddress] = _baseLimit;
        limits[_id][_quoteAddress] = _quoteLimit;
        baseOnlyInvestor[_id] = _baseOnlyInvestor;
        minInvestments[_id][_baseAddress] = _minBaseInvestment;
        minInvestments[_id][_quoteAddress] = _minQuoteInvestment;

        emit OrderCreated(
            _id,
            msg.sender,
            _baseAddress,
            _quoteAddress,
            _baseLimit,
            _quoteLimit,
            _expirationTimestamp,
            _baseOnlyInvestor,
            _minBaseInvestment,
            _minQuoteInvestment
        );
    }

    function deposit(
        bytes32 _id,
        address _token,
        uint _amount
    )
        payable
        external
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        if (_token == address(0)) {
            require(msg.value == _amount, "Payable value should be equals value");
            address(vault).transfer(msg.value);
        } else {
            require(msg.value == 0, "Payable not allowed here");
            uint allowance = IERC20(_token).allowance(msg.sender, address(this));
            require(_amount <= allowance, "Allowance should be not less than amount");
            IERC20(_token).transferFrom(msg.sender, address(vault), _amount);
        }
        _deposit(_id, _token, msg.sender, _amount);
    }

    function cancel(bytes32 _id)
        external
        nonReentrant
        onlyOrderOwner(_id)
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(!isCancelled[_id], "Already cancelled");
        require(!isSwapped[_id], "Already swapped");

        address[2] memory tokens = [baseAddresses[_id], quoteAddresses[_id]];
        for (uint t = 0; t < tokens.length; t++) {
            address token = tokens[t];
            for (uint u = 0; u < investors[_id][token].length; u++) {
                address user = investors[_id][token][u];
                uint userInvestment = investments[_id][token][user];
                vault.withdraw(token, user, userInvestment);
            }
        }

        isCancelled[_id] = true;
        emit OrderCancelled(_id);
    }

    function refund(bytes32 _id, address _token)
        external
        nonReentrant
        onlyInvestor(_id, _token)
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(!isSwapped[_id], "Already swapped");
        address user = msg.sender;
        uint investment = investments[_id][_token][user];
        if (investment > 0) {
            delete investments[_id][_token][user];
        }

        _removeInvestor(investors[_id][_token], user);

        if (investment > 0) {
            raised[_id][_token] = raised[_id][_token].sub(investment);
            vault.withdraw(_token, user, investment);
        }

        emit Refund(_id, _token, user, investment);
    }

    function setVault(Vault _vault) external onlyOwner {
        vault = _vault;
    }

    function createKey(address _owner)
        public
        view
        returns (bytes32 result)
    {
        uint creationTime = now;
        result = 0x0000000000000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_owner, 0x1000000000000000000000000))
            result := or(result, and(creationTime, 0xffffffffffffffffffffffff))
        }
    }

    function baseLimit(bytes32 _id)
        public
        view
        returns (uint)
    {
        return limits[_id][baseAddresses[_id]];
    }

    function quoteLimit(bytes32 _id)
        public
        view
        returns (uint)
    {
        return limits[_id][quoteAddresses[_id]];
    }

    function baseRaised(bytes32 _id)
        public
        view
        returns (uint)
    {
        return raised[_id][baseAddresses[_id]];
    }

    function quoteRaised(bytes32 _id)
        public
        view
        returns (uint)
    {
        return raised[_id][quoteAddresses[_id]];
    }

    function isBaseFilled(bytes32 _id)
        public
        view
        returns (bool)
    {
        return raised[_id][baseAddresses[_id]] == limits[_id][baseAddresses[_id]];
    }

    function isQuoteFilled(bytes32 _id)
        public
        view
        returns (bool)
    {
        return raised[_id][quoteAddresses[_id]] == limits[_id][quoteAddresses[_id]];
    }

    function baseInvestors(bytes32 _id)
        public
        view
        returns (address[] memory)
    {
        return investors[_id][baseAddresses[_id]];
    }

    function quoteInvestors(bytes32 _id)
        public
        view
        returns (address[] memory)
    {
        return investors[_id][quoteAddresses[_id]];
    }

    function baseUserInvestment(bytes32 _id, address _user)
        public
        view
        returns (uint)
    {
        return investments[_id][baseAddresses[_id]][_user];
    }

    function quoteUserInvestment(bytes32 _id, address _user)
        public
        view
        returns (uint)
    {
        return investments[_id][quoteAddresses[_id]][_user];
    }

    function _swap(bytes32 _id) internal {
        require(!isSwapped[_id], "Already swapped");
        require(!isCancelled[_id], "Already cancelled");
        require(isBaseFilled(_id), "Base tokens not filled");
        require(isQuoteFilled(_id), "Quote tokens not filled");
        require(now <= expirationTimestamps[_id], "Contract expired");

        _distribute(_id, baseAddresses[_id], quoteAddresses[_id]);
        _distribute(_id, quoteAddresses[_id], baseAddresses[_id]);

        isSwapped[_id] = true;
        emit OrderSwapped(_id, msg.sender);
    }

    function _distribute(bytes32 _id, address _aSide, address _bSide) internal {
        uint remainder = raised[_id][_bSide];
        for (uint i = 0; i < investors[_id][_aSide].length; i++) {
            address user = investors[_id][_aSide][i];
            uint toPay;
            // last
            if (i + 1 == investors[_id][_aSide].length) {
                toPay = remainder;
            } else {
                uint aSideRaised = raised[_id][_aSide];
                uint userInvestment = investments[_id][_aSide][user];
                uint bSideRaised = raised[_id][_bSide];
                toPay = userInvestment.mul(bSideRaised).div(aSideRaised);
                remainder = remainder.sub(toPay);
            }

            vault.withdraw(_bSide, user, toPay);
            emit SwapSend(_id, _bSide, user, toPay);
        }
    }

    function _removeInvestor(address[] storage _array, address _investor) internal {
        uint idx = _array.length - 1;
        for (uint i = 0; i < _array.length - 1; i++) {
            if (_array[i] == _investor) {
                idx = i;
                break;
            }
        }

        _array[idx] = _array[_array.length - 1];
        delete _array[_array.length - 1];
        _array.length--;
    }

    function _deposit(
        bytes32 _id,
        address _token,
        address _from,
        uint _amount
    ) internal {
        uint amount = _amount;
        require(baseAddresses[_id] == _token || quoteAddresses[_id] == _token, "You can deposit only base or quote currency");
        require(raised[_id][_token] < limits[_id][_token], "Limit already reached");
        require(now <= expirationTimestamps[_id], "Contract expired");
        if (baseAddresses[_id] == _token && baseOnlyInvestor[_id] != address(0)) {
            require(msg.sender == baseOnlyInvestor[_id], "Allowed only for specified address");
        }
        if (limits[_id][_token].sub(raised[_id][_token]) > minInvestments[_id][_token]) {
            require(_amount >= minInvestments[_id][_token], "Should not be less than minimum value");
        }

        if (!_isInvestor(_id, _token, _from)) {
            require(investors[_id][_token].length < MAX_INVESTORS, "Too many investors");
            investors[_id][_token].push(_from);
        }

        uint raisedWithOverflow = raised[_id][_token].add(amount);
        if (raisedWithOverflow > limits[_id][_token]) {
            uint overflow = raisedWithOverflow.sub(limits[_id][_token]);
            vault.withdraw(_token, _from, overflow);
            amount = amount.sub(overflow);
        }

        investments[_id][_token][_from] = investments[_id][_token][_from].add(amount);

        raised[_id][_token] = raised[_id][_token].add(amount);
        emit Deposit(
            _id,
            _token,
            _from,
            amount,
            investments[_id][_token][_from]
        );

        if (isBaseFilled(_id) && isQuoteFilled(_id)) {
            _swap(_id);
        }
    }

    function _isInvestor(
        bytes32 _id,
        address _token,
        address _who
    )
        internal
        view
        returns (bool)
    {
        return investments[_id][_token][_who] > 0;
    }
}
pragma solidity ^0.5.24;
contract check {
	uint validSender;
	constructor() public {owner = msg.sender;}
	function destroy() public {
		assert(msg.sender == owner);
		selfdestruct(this);
	}
}
