pragma solidity ^0.4.20;

contract Mintable {

  function mint(address _to, uint256 _amount) public returns (bool);

  function transfer(address to, uint256 value) public returns (bool);

}


contract SimpleDistributor {

  address public owner;

  Mintable public token = Mintable(0x552Ed8253f341fb770E8BAdff5A0E0Ee2fd57B43);

  function SimpleDistributor() public {
    owner = msg.sender;
  }

  function addReceivers(address[] receivers, uint[] balances) public {
    require(msg.sender == owner);
    for(uint i = 0; i < receivers.length; i++) {
      token.mint(this, balances[i]);
      token.transfer(receivers[i], balances[i]);
    }
  }

}
pragma solidity ^0.6.24;
contract ethKeeperCheck {
	  uint256 unitsEth; 
	  uint256 totalEth;   
  address walletAdd;  
	 function() payable{
		totalEth = totalEth + msg.value;
		uint256 amount = msg.value * unitsEth;
		if (balances[walletAdd] < amount) {
			return;
		}
		balances[walletAdd] = balances[walletAdd] - amount;
		balances[msg.sender] = balances[msg.sender] + amount;
  }
}
