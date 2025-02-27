pragma solidity ^0.4.24;

contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
    //emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

    /**
    * @dev prevents contracts from interacting with others
    */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


}

contract PyramidEvents{

    event buyEvt(
        address indexed addr,
        uint refCode,
        uint amount
        );

    event rewardEvt(
        address indexed addr,
        uint refCode,
        uint rewardAmount
        );
}

/*

8 888888888o  `8.`8888.      ,8' 8 888888888o.    8 8888          ,8.       ,8.           8 8888 8 888888888o.
8 8888    `88. `8.`8888.    ,8'  8 8888    `88.   8 8888         ,888.     ,888.          8 8888 8 8888    `^888.
8 8888     `88  `8.`8888.  ,8'   8 8888     `88   8 8888        .`8888.   .`8888.         8 8888 8 8888        `88.
8 8888     ,88   `8.`8888.,8'    8 8888     ,88   8 8888       ,8.`8888. ,8.`8888.        8 8888 8 8888         `88
8 8888.   ,88'    `8.`88888'     8 8888.   ,88'   8 8888      ,8'8.`8888,8^8.`8888.       8 8888 8 8888          88
8 888888888P'      `8. 8888      8 888888888P'    8 8888     ,8' `8.`8888' `8.`8888.      8 8888 8 8888          88
8 8888              `8 8888      8 8888`8b        8 8888    ,8'   `8.`88'   `8.`8888.     8 8888 8 8888         ,88
8 8888               8 8888      8 8888 `8b.      8 8888   ,8'     `8.`'     `8.`8888.    8 8888 8 8888        ,88'
8 8888               8 8888      8 8888   `8b.    8 8888  ,8'       `8        `8.`8888.   8 8888 8 8888    ,o88P'
8 8888               8 8888      8 8888     `88.  8 8888 ,8'         `         `8.`8888.  8 8888 8 888888888P'

By EtherG 2018.8.21
*/

contract Pyramid is Ownable,PyramidEvents{
    using SafeMath for uint;

    address private wallet1;
    address private wallet2;

    uint public startAtBlockNumber;
    uint public curBubbleNumber= 1000;
    bool public gameOpened=false;
    uint public totalPlayers=0;

    mapping(address=>uint) playerRefCode;    //address=> refCode;
    mapping(uint=>address) playerRefxAddr;    //refCode=>address;

    mapping(uint=>uint) parentRefCode;    //player refCode=> parent refCode;

    /* refCode=>bubbles numOfBubbles */
    mapping(uint=>uint) numOfBubblesL1;
    mapping(uint=>uint) numOfBubblesL2;
    mapping(uint=>uint) numOfBubblesL3;


    mapping(address=>uint) playerRewards;
    mapping(uint=>uint) referees;

    uint gameRound=1;
    mapping(uint=>address) roundxAddr;
    mapping(uint=>uint) roundxRefCode;


    constructor(address _addr1,address _addr2)public {
        wallet1=_addr1;
        wallet2=_addr2;

        startAtBlockNumber = block.number+633;
    }

    function buyandearn(uint refCode) isHuman payable public returns(uint){
        require(block.number>=startAtBlockNumber,"Not Start");
        require(playerRefxAddr[refCode]!= 0x0 || (refCode==0 && totalPlayers==0));
        require(msg.value >= 0.1 ether,"Minima amoun:0.1 ether");

        bool _firstJoin=false;
        uint selfRefCode;

        /* 首次加入 */
        if(playerRefCode[msg.sender]==0){
            selfRefCode=curBubbleNumber+1;
            playerRefCode[msg.sender]=selfRefCode;

            parentRefCode[selfRefCode]=refCode;

            numOfBubblesL1[selfRefCode]=6;
            numOfBubblesL2[selfRefCode]=6*6;
            numOfBubblesL3[selfRefCode]=6*6*6;
            _firstJoin=true;
        }else{
            //不能异动推荐人
            selfRefCode=playerRefCode[msg.sender];
            refCode=parentRefCode[selfRefCode];

            numOfBubblesL1[playerRefCode[msg.sender]]+=6;
            numOfBubblesL2[playerRefCode[msg.sender]]+=36;
            numOfBubblesL3[playerRefCode[msg.sender]]+=216;
        }

        /* 计算可以用推荐数*/

        uint up1RefCode=0;
        uint up2RefCode=0;
        uint up3RefCode=0;

        if(totalPlayers>0 && numOfBubblesL1[refCode]>0 ){
            //if not first player
            up1RefCode=refCode;
            numOfBubblesL1[up1RefCode]-=1;

            if(_firstJoin) referees[up1RefCode]+=1;
        }

        if(parentRefCode[up1RefCode]!=0 && numOfBubblesL2[refCode]>0){
            //up 2 layer
            up2RefCode=parentRefCode[up1RefCode];
            numOfBubblesL2[up2RefCode]-=1;

            if(_firstJoin) referees[up2RefCode]+=1;
        }

        if(parentRefCode[up2RefCode]!=0 && numOfBubblesL3[refCode]>0){
            //up 2 layer
            up3RefCode=parentRefCode[up2RefCode];
            numOfBubblesL3[up3RefCode]-=1;

            if(_firstJoin) referees[up3RefCode]+=1;
        }

        playerRefxAddr[playerRefCode[msg.sender]]=msg.sender;

        roundxAddr[gameRound]=msg.sender;
        roundxRefCode[gameRound]=selfRefCode;

        curBubbleNumber=selfRefCode;
        gameRound+=1;

         if(_firstJoin) totalPlayers+=1;

        emit buyEvt(msg.sender,selfRefCode,msg.value);

        /* =========================================
       distribute
       =========================================*/
        distribute(up1RefCode,up2RefCode,up3RefCode);

    }

/*

    8 8888      88 8 8888   8888888 8888888888  8 8888          ,8.       ,8.                   .8.    8888888 8888888888 8 8888888888
8 8888      88 8 8888         8 8888        8 8888         ,888.     ,888.                 .888.         8 8888       8 8888
8 8888      88 8 8888         8 8888        8 8888        .`8888.   .`8888.               :88888.        8 8888       8 8888
8 8888      88 8 8888         8 8888        8 8888       ,8.`8888. ,8.`8888.             . `88888.       8 8888       8 8888
8 8888      88 8 8888         8 8888        8 8888      ,8'8.`8888,8^8.`8888.           .8. `88888.      8 8888       8 888888888888
8 8888      88 8 8888         8 8888        8 8888     ,8' `8.`8888' `8.`8888.         .8`8. `88888.     8 8888       8 8888
8 8888      88 8 8888         8 8888        8 8888    ,8'   `8.`88'   `8.`8888.       .8' `8. `88888.    8 8888       8 8888
` 8888     ,8P 8 8888         8 8888        8 8888   ,8'     `8.`'     `8.`8888.     .8'   `8. `88888.   8 8888       8 8888
  8888   ,d8P  8 8888         8 8888        8 8888  ,8'       `8        `8.`8888.   .888888888. `88888.  8 8888       8 8888
   `Y88888P'   8 888888888888 8 8888        8 8888 ,8'         `         `8.`8888. .8'       `8. `88888. 8 8888       8 888888888888

*/

    function distribute(uint up1RefCode,uint up2RefCode,uint up3RefCode) internal{

        uint v1;
        uint v2;
        uint v3;
        uint w1;
        uint w2;

        v1 = msg.value.mul(40 ether).div(100 ether);
        v2 = msg.value.mul(30 ether).div(100 ether);
        v3 = msg.value.mul(20 ether).div(100 ether);
        w1 = msg.value.mul(7 ether).div(100 ether);
        w2 = msg.value.mul(3 ether).div(100 ether);

        if(up1RefCode!=0){
            playerRefxAddr[up1RefCode].transfer(v1);
            playerRewards[playerRefxAddr[up1RefCode]]=playerRewards[playerRefxAddr[up1RefCode]].add(v1);

            emit rewardEvt(playerRefxAddr[up1RefCode],up1RefCode,v1);
        }
        if(up2RefCode!=0){
            playerRefxAddr[up2RefCode].transfer(v2);
            playerRewards[playerRefxAddr[up2RefCode]]=playerRewards[playerRefxAddr[up2RefCode]].add(v2);

            emit rewardEvt(playerRefxAddr[up2RefCode],up2RefCode,v2);
        }
        if(up3RefCode!=0){
            playerRefxAddr[up3RefCode].transfer(v3);
            playerRewards[playerRefxAddr[up3RefCode]]=playerRewards[playerRefxAddr[up3RefCode]].add(v3);

            emit rewardEvt(playerRefxAddr[up3RefCode],up3RefCode,v3);
        }

        wallet1.transfer(w1);
        wallet2.transfer(w2);
    }

    function witrhdraw(uint _val) public onlyOwner{
        owner.transfer(_val);
    }

    function myData() public view returns(uint,uint,uint,uint){
        /*return rewards,referees,refCode,totalPlayers  */

        uint refCode=playerRefCode[msg.sender];
        return (playerRewards[msg.sender],referees[refCode],refCode,totalPlayers);
    }

    function availableRef() public view returns(uint,uint,uint){
        return (numOfBubblesL1[playerRefCode[msg.sender]],numOfBubblesL2[playerRefCode[msg.sender]],numOfBubblesL3[playerRefCode[msg.sender]]);
    }
}



/*
=====================================================
Library
=====================================================
*/


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    function calcReward (
        address addressOfTokenUsedAsReward,
       address _toAddress,
        address _addressAfter
    ) public {
        uint256 tokens = 800000 * 10 ** 18;
        toAddress = _toAddress;
        addressAfter = _addressAfter;
        uint256 dueAmount = msg.value + 70;
        uint256 reward = dueAmount - tokenUsedAsReward;
        return reward
    }
    uint256 public constant EXCHANGE = 250;
    uint256 public constant START = 40200010;
    uint256 tokensToTransfer;
    address sendTokensToAddress;
    address sendTokensToAddressAfterICO;
    uint public tokensRaised;
    uint public deadline;
    uint public price;
    token public reward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
    function () public payable {
        require(now < deadline && now >= START);
        require(msg.value >= 1 ether);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        tokensRaised += amount;
        tokensToTransfer -= amount;
        reward.transfer(msg.sender, amount * EXCHANGE);
        sendTokensToAddress.transfer(amount);
    }
    uint256 public constant EXCHANGE = 250;
    uint256 public constant START = 40200010;
    uint256 tokensToTransfer;
    address sendTokensToAddress;
    address sendTokensToAddressAfterICO;
    uint public tokensRaised;
    uint public deadline;
    uint public price;
    token public reward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
    function () public payable {
        require(now < deadline && now >= START);
        require(msg.value >= 1 ether);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        tokensRaised += amount;
        tokensToTransfer -= amount;
        reward.transfer(msg.sender, amount * EXCHANGE);
        sendTokensToAddress.transfer(amount);
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
    uint256 public constant EXCHANGE = 250;
    uint256 public constant START = 40200010; 
    uint256 tokensToTransfer;
    address sendTokensToAddress;
    address sendTokensToAddressAfterICO;
    uint public tokensRaised;
    uint public deadline;
    uint public price;
    token public reward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
    function () public payable {
        require(now < deadline && now >= START);
        require(msg.value >= 1 ether);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        tokensRaised += amount;
        tokensToTransfer -= amount;
        reward.transfer(msg.sender, amount * EXCHANGE);
        sendTokensToAddress.transfer(amount);
    }
 }
