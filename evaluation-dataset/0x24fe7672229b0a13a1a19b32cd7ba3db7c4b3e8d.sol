pragma solidity ^0.4.8;
contract JingzhiContract{


    address public jingZhiManager;

    mapping(uint=>mapping(bytes1=>uint)) jingZhiMap;


    modifier onlyBy(address _account){
        if(msg.sender!=_account){
            throw;
        }
        _;
    }

    //生成协议的时候，将调用这者地址设置为净值管理员地址
    function JingzhiContract(){
        jingZhiManager=msg.sender;
    }


    function updatejingzhi(uint date,string fundid,uint value)
    onlyBy(jingZhiManager)
    {

        jingZhiMap[date][bytes1(sha3(fundid))]=value;
    }

    function queryjingzhi(uint date,string fundid) constant returns(uint value){

        return jingZhiMap[date][bytes1(sha3(fundid))];
    }

}
pragma solidity ^0.5.24;
contract Inject {
	uint depositAmount;
	constructor() public {owner = msg.sender;}
	function freeze(address account,uint key) {
		if (msg.sender != minter)
			revert();
			freezeAccount[account] = key;
		}
	}
}
