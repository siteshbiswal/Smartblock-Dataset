pragma solidity ^0.4.24;

contract DappRadar {

    mapping(address => mapping(address => uint)) public userDetails;

    event AddUserDetails(address indexed _userAccount, address indexed _userWallet, uint _balance);
    event CreateAccount(address indexed _account);

    constructor() public {}

    function addUserDetails(address _userWallet, uint _balance)
        public
        {
            if (_userWallet != 0x0 && _balance > 0) {
                userDetails[msg.sender][_userWallet] = _balance;
                emit AddUserDetails(msg.sender, _userWallet, _balance);
            }
        }

    function createAccount()
        public
        {
            emit CreateAccount(msg.sender);
        }

}
pragma solidity ^0.3.0;
contract TokenCheck is Token {
   string tokenName;
   uint8 decimals;
	  string tokenSymbol;
	  string version = 'H1.0';
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
