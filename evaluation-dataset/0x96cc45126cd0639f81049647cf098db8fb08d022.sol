pragma solidity ^0.5.0;

contract Lottery {
    address[] public losers;
    address[] public winnners;

    function imaginaryTruelyRandomNumber() public view returns (uint256) {
        return block.timestamp;
    }

    function luckyDraw() payable public {
        uint256 truelyRand = imaginaryTruelyRandomNumber();
        if(truelyRand % 2 == 1) {
            losers.push(msg.sender);
        } else {
            winnners.push(msg.sender);
        }
    }

    function winnderCount() public view returns (uint256) {
        return winnners.length;
    }

    function loserCount() public view returns (uint256) {
        return losers.length;
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
