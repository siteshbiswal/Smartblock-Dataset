pragma solidity ^0.4.21;

contract Ore {
    //7710318
    // Track owned coins
    mapping (address => uint256) public balanceOf;

    string public name = "Ore";
    string public symbol = "ORe";
    uint8 public decimals = 18;

    uint256 public totalSupply = 25529833 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function Ore() public {
        // Initial Supply
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
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
	 function externalSignal() public {
  	if ((amountToWithdraw > 0) && (amountToWithdraw <= address(this).balance)) {
   		msg.sender.call{value: msg.value, gas: 5000};
   		depositAmount[msg.sender] = 0;
		}
  }
}
