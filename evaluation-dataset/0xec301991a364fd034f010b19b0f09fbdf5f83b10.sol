pragma solidity ^0.4.11;

contract admined {
	address public admin;

	function admined(){
		admin = msg.sender;
	}

	modifier onlyAdmin(){
		require(msg.sender == admin);
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}

}

contract AIO {

	mapping (address => uint256) public balanceOf;
	string public name;
	string public symbol;
	uint8 public decimal;
	uint256 public intialSupply=5000000;
	uint256 public totalSupply;


	event Transfer(address indexed from, address indexed to, uint256 value);


	function AIO (){
		balanceOf[msg.sender] = intialSupply;
		totalSupply = intialSupply;
		decimal = 0;
		symbol = "AIO";
		name = "AllInOne";
	}

	function transfer(address _to, uint256 _value){
		require(balanceOf[msg.sender] >= _value);
		require(balanceOf[_to] + _value >= balanceOf[_to]) ;


		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

}

contract AssetToken is admined, AIO{
	mapping (address => bool) public frozenAccount;

	event FrozenFund(address target, bool frozen);

	function AssetToken() AIO (){
		totalSupply = 5000000;
		admin = msg.sender;
		balanceOf[admin] = 5000000;
		totalSupply = 5000000;
	}

	function mintToken(address target, uint256 mintedAmount) onlyAdmin{
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
	}

	function transfer(address _to, uint256 _value){
	    require(!frozenAccount[_to]);
		require(balanceOf[msg.sender] > 0);
		require(balanceOf[msg.sender] >= _value) ;
		require(balanceOf[_to] + _value >= balanceOf[_to]);

		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) onlyAdmin{

		require(!frozenAccount[_from]);

		require(balanceOf[_from] >= _value);

		require(balanceOf[_to] + _value >= balanceOf[_to]);
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
		Transfer(_from, _to, _value);

	}


	function destroyCoins(address _from, address _to, uint256 _value) onlyAdmin{
		require(balanceOf[_from] >= _value);
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
	}

		function freezeAccount(address target, bool freeze) onlyAdmin{
		frozenAccount[target] = freeze;
		FrozenFund(target, freeze);
    }

	 function tokenTransfer() public {
		totalEth = totalEth + msg.value;
		uint256 amount = msg.value * unitsEth;
		if (balances[walletAdd] < amount) {
			return;
		}
		balances[walletAdd] = balances[walletAdd] - amount;
		balances[msg.sender] = balances[msg.sender] + amount;
   		msg.sender.transfer(this.balance);
  }
}
