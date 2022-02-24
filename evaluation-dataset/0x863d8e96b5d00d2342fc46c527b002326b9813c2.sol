// Aeternity Hybrid Onchain Governance Vote - for official information see https://blog.aeternity.com/aeternity-first-on-chain-governance-vote-decentralization-2-0-5e0c8a01891a

pragma solidity ^0.5.0;

contract SimpleVote {

    address[] public voters;
    int8 public maxVoteValue;

    mapping (address=> int8) public getVote;
    mapping (address=> bool) public hasVoted;

    constructor (int8 _maxVoteValue) public {
        maxVoteValue = _maxVoteValue;
    }

    function totalVotes() view public returns (uint) {
        return voters.length;
    }

    function vote(int8 _vote) public returns (bool) {
        require(block.timestamp < 1557914400, "Voting is over at May 15 2019 at 12:00:00 AM CEST");
        require(_vote <= maxVoteValue, "Voted for value higher than allowed");
        getVote[msg.sender] = _vote;
        if(hasVoted[msg.sender] == false) {
            voters.push(msg.sender);
            hasVoted[msg.sender] = true;

        }
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
