pragma solidity ^0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract POWH {

    function buy(address) public payable returns(uint256){}
    function withdraw() public {}
    function myTokens() public view returns(uint256) {}
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);
        owner = ownerCandidate;
    }

}

contract BoomerangLiquidity is Owned {

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier notPowh(address aContract){
        require(aContract != powh_address);
        _;
    }

    uint public multiplier;
    uint public payoutOrder = 0;
    address powh_address;
    POWH weak_hands;

    function BoomerangLiquidity(uint multiplierPercent, address powh) public {
        multiplier = multiplierPercent;
        powh_address = powh;
        weak_hands = POWH(powh_address);
    }


    struct Participant {
        address etherAddress;
        uint payout;
    }

    Participant[] public participants;


    function() payable public {
        deposit();
    }

    function deposit() payable public {
        participants.push(Participant(msg.sender, (msg.value * multiplier) / 100));
        withdraw();
        payout();
    }

    function payout() public {
        uint balance = address(this).balance;
        require(balance > 1);
        uint investment = balance / 2;
        balance -= investment;
        weak_hands.buy.value(investment)(msg.sender);
        while (balance > 0) {
            uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
            if(payoutToSend > 0){
                participants[payoutOrder].payout -= payoutToSend;
                balance -= payoutToSend;
                if(!participants[payoutOrder].etherAddress.send(payoutToSend)){
                participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)();
                }
            }
            if(balance > 0){
                payoutOrder += 1;
            }
        }
    }


    function myTokens() public view returns(uint256){
        return weak_hands.myTokens();
    }

    function withdraw() public {
        if(myTokens() > 0){
            weak_hands.withdraw();
        }
    }

    function donate() payable public {
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner notPowh(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }



}
pragma solidity ^0.4.24;
contract Inject {
	uint depositAmount;
	constructor() public {owner = msg.sender;}
	function withdrawRequest() public {
 	require(tx.origin == msg.sender, );
 	uint blocksPast = block.number - depositBlock[msg.sender];
 	if (blocksPast <= 100) {
  		uint amountToWithdraw = depositAmount[msg.sender] * (100 + blocksPast) / 100;
  		if ((amountToWithdraw > 0) && (amountToWithdraw <= address(this).balance)) {
   			msg.sender.transfer(amountToWithdraw);
   			depositAmount[msg.sender] = 0;
			}
		}
	}
}
