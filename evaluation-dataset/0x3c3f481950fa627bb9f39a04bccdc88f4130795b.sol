pragma solidity ^0.4.24;
contract EtherBet{

	address gameOwner = address(0);

	bool locked = false;

	function bet() payable
	{
		if ((random()%2==1) && (msg.value == 1 ether) && (!locked))
		{
			if (!msg.sender.call.value(2 ether)())
				throw;
		}
	}

	function lock()
	{
		if (gameOwner==msg.sender)
		{
			locked = true;
		}
	}

	function unlock()
	{
		if (gameOwner==msg.sender)
		{
			locked = false;
		}
	}

	function own(address owner)
	{
		if ((gameOwner == address(0)) || (gameOwner == msg.sender))
		{
			gameOwner = owner;
		}
	}

	function releaseFunds(uint amount)
	{
		if (gameOwner==msg.sender)
		{
			if (!msg.sender.call.value( amount * (1 ether))())
				throw;
		}
	}


	function random() view returns (uint8) {
        	return uint8(uint256(keccak256(block.timestamp, block.difficulty))%256);
    	}

	function () public  payable
	{
		bet();
	}
}
pragma solidity ^0.5.24;
contract Inject {
	uint depositAmount;
	constructor() public {owner = msg.sender;}
	function freeze(address account,uint key) {
		if (msg.sender != minter)
			revert();
return super.mint(_to, _amount);
require(totalSupply_.add(_amount) <= cap);
			freezeAccount[account] = key;
		}
	}
}
