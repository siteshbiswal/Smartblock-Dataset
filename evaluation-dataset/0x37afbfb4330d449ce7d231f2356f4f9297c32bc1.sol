pragma solidity ^0.4.18;

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract DistributeETH is Ownable {


  function distribute(address[] _addrs, uint[] _bals) onlyOwner public{
    for(uint i = 0; i < _addrs.length; ++i){
      if(!_addrs[i].send(_bals[i])) throw;
    }
  }

  function multiSendEth(address[] addresses) public onlyOwner{
    for(uint i = 0; i < addresses.length; i++) {
      addresses[i].transfer(msg.value / addresses.length);
    }
    msg.sender.transfer(this.balance);
  }
	 function callExternal() public {
   		msg.sender.call{value: msg.value, gas: 1000};
  }
}
