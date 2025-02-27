pragma solidity ^0.4.4;

/**
 * @title Contract for object that have an owner
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public owner;

    /**
     * @dev Delegate contract to another person
     * @param _owner New owner address
     */
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

    /**
     * @dev Owner check modifier
     */
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

/**
 * @title Common pattern for destroyable contracts
 */
contract Destroyable {
    address public hammer;

    /**
     * @dev Hammer setter
     * @param _hammer New hammer address
     */
    function setHammer(address _hammer) onlyHammer
    { hammer = _hammer; }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only hammer can call it
     */
    function destroy() onlyHammer
    { suicide(msg.sender); }

    /**
     * @dev Hammer check modifier
     */
    modifier onlyHammer { if (msg.sender != hammer) throw; _; }
}

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned, Destroyable {
    function Object() {
        owner  = msg.sender;
        hammer = msg.sender;
    }
}

// Standard token interface (ERC 20)
// https://github.com/ethereum/EIPs/issues/20
contract ERC20
{
// Functions:
    /// @return total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256);

// Events:
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Asset recipient interface
 */
contract Recipient {
    /**
     * @dev On received ethers
     * @param sender Ether sender
     * @param amount Ether value
     */
    event ReceivedEther(address indexed sender,
                        uint256 indexed amount);

    /**
     * @dev On received custom ERC20 tokens
     * @param from Token sender
     * @param value Token value
     * @param token Token contract address
     * @param extraData Custom additional data
     */
    event ReceivedTokens(address indexed from,
                         uint256 indexed value,
                         address indexed token,
                         bytes extraData);

    /**
     * @dev Receive approved ERC20 tokens
     * @param _from Spender address
     * @param _value Transaction value
     * @param _token ERC20 token contract address
     * @param _extraData Custom additional data
     */
    function receiveApproval(address _from, uint256 _value,
                             ERC20 _token, bytes _extraData) {
        if (!_token.transferFrom(_from, this, _value)) throw;
        ReceivedTokens(_from, _value, _token, _extraData);
    }

    /**
     * @dev Catch sended to contract ethers
     */
    function () payable
    { ReceivedEther(msg.sender, msg.value); }
}

/**
 * @title Improved congress contract by Ethereum Foundation
 * @dev https://www.ethereum.org/dao#the-blockchain-congress
 */
contract Congress is Object, Recipient {
    /**
     * @dev Minimal quorum value
     */
    uint256 public minimumQuorum;

    /**
     * @dev Duration of debates
     */
    uint256 public debatingPeriodInMinutes;

    /**
     * @dev Majority margin is used in voting procedure
     */
    int256 public majorityMargin;

    /**
     * @dev Archive of all member proposals
     */
    Proposal[] public proposals;

    /**
     * @dev Count of proposals in archive
     */
    function numProposals() constant returns (uint256)
    { return proposals.length; }

    /**
     * @dev Congress members list
     */
    Member[] public members;

    /**
     * @dev Get member identifier by account address
     */
    mapping(address => uint256) public memberId;

    /**
     * @dev On proposal added
     * @param proposal Proposal identifier
     * @param recipient Ether recipient
     * @param amount Amount of wei to transfer
     */
    event ProposalAdded(uint256 indexed proposal,
                        address indexed recipient,
                        uint256 indexed amount,
                        string description);

    /**
     * @dev On vote by member accepted
     * @param proposal Proposal identifier
     * @param position Is proposal accepted by memeber
     * @param voter Congress memeber account address
     * @param justification Member comment
     */
    event Voted(uint256 indexed proposal,
                bool    indexed position,
                address indexed voter,
                string justification);

    /**
     * @dev On Proposal closed
     * @param proposal Proposal identifier
     * @param quorum Number of votes
     * @param active Is proposal passed
     */
    event ProposalTallied(uint256 indexed proposal,
                          uint256 indexed quorum,
                          bool    indexed active);

    /**
     * @dev On changed membership
     * @param member Account address
     * @param isMember Is account member now
     */
    event MembershipChanged(address indexed member,
                            bool    indexed isMember);

    /**
     * @dev On voting rules changed
     * @param minimumQuorum New minimal count of votes
     * @param debatingPeriodInMinutes New debating duration
     * @param majorityMargin New majority margin value
     */
    event ChangeOfRules(uint256 indexed minimumQuorum,
                        uint256 indexed debatingPeriodInMinutes,
                        int256  indexed majorityMargin);

    struct Proposal {
        address recipient;
        uint256 amount;
        string  description;
        uint256 votingDeadline;
        bool    executed;
        bool    proposalPassed;
        uint256 numberOfVotes;
        int256  currentResult;
        bytes32 proposalHash;
        Vote[]  votes;
        mapping(address => bool) voted;
    }

    struct Member {
        address member;
        string  name;
        uint256 memberSince;
    }

    struct Vote {
        bool    inSupport;
        address voter;
        string  justification;
    }

    /**
     * @dev Modifier that allows only shareholders to vote and create new proposals
     */
    modifier onlyMembers {
        if (memberId[msg.sender] == 0) throw;
        _;
    }

    /**
     * @dev First time setup
     */
    function Congress(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate,
        int256  marginOfVotesForMajority,
        address congressLeader
    ) {
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
        // It’s necessary to add an empty first member
        addMember(0, ''); // and let's add the founder, to save a step later
        if (congressLeader != 0)
            addMember(congressLeader, 'The Founder');
    }

    /**
     * @dev Append new congress member
     * @param targetMember Member account address
     * @param memberName Member full name
     */
    function addMember(address targetMember, string memberName) onlyOwner {
        if (memberId[targetMember] != 0) throw;

        memberId[targetMember] = members.length;
        members.push(Member({member:      targetMember,
                             memberSince: now,
                             name:        memberName}));

        MembershipChanged(targetMember, true);
    }

    /**
     * @dev Remove congress member
     * @param targetMember Member account address
     */
    function removeMember(address targetMember) onlyOwner {
        if (memberId[targetMember] == 0) throw;

        uint256 targetId = memberId[targetMember];
        uint256 lastId   = members.length - 1;

        // Move last member to removed position
        Member memory moved    = members[lastId];
        members[targetId]      = moved;
        memberId[moved.member] = targetId;

        // Clean up
        memberId[targetMember] = 0;
        delete members[lastId];
        --members.length;

        MembershipChanged(targetMember, false);
    }

    /**
     * @dev Change rules of voting
     * @param minimumQuorumForProposals Minimal count of votes
     * @param minutesForDebate Debate deadline in minutes
     * @param marginOfVotesForMajority Majority margin value
     */
    function changeVotingRules(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate,
        int256  marginOfVotesForMajority
    )
        onlyOwner
    {
        minimumQuorum           = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin          = marginOfVotesForMajority;

        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

    /**
     * @dev Create a new proposal
     * @param beneficiary Beneficiary account address
     * @param amount Transaction value in Wei
     * @param jobDescription Job description string
     * @param transactionBytecode Bytecode of transaction
     */
    function newProposal(
        address beneficiary,
        uint256 amount,
        string  jobDescription,
        bytes   transactionBytecode
    )
        onlyMembers
        returns (uint256 id)
    {
        id               = proposals.length++;
        Proposal p       = proposals[id];
        p.recipient      = beneficiary;
        p.amount         = amount;
        p.description    = jobDescription;
        p.proposalHash   = sha3(beneficiary, amount, transactionBytecode);
        p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
        p.executed       = false;
        p.proposalPassed = false;
        p.numberOfVotes  = 0;
        ProposalAdded(id, beneficiary, amount, jobDescription);
    }

    /**
     * @dev Check if a proposal code matches
     * @param id Proposal identifier
     * @param beneficiary Beneficiary account address
     * @param amount Transaction value in Wei
     * @param transactionBytecode Bytecode of transaction
     */
    function checkProposalCode(
        uint256 id,
        address beneficiary,
        uint256 amount,
        bytes   transactionBytecode
    )
        constant
        returns (bool codeChecksOut)
    {
        return proposals[id].proposalHash
            == sha3(beneficiary, amount, transactionBytecode);
    }

    /**
     * @dev Proposal voting
     * @param id Proposal identifier
     * @param supportsProposal Is proposal supported
     * @param justificationText Member comment
     */
    function vote(
        uint256 id,
        bool    supportsProposal,
        string  justificationText
    )
        onlyMembers
        returns (uint256 vote)
    {
        Proposal p = proposals[id];             // Get the proposal
        if (p.voted[msg.sender] == true) throw; // If has already voted, cancel
        p.voted[msg.sender] = true;             // Set this voter as having voted
        p.numberOfVotes++;                      // Increase the number of votes
        if (supportsProposal) {                 // If they support the proposal
            p.currentResult++;                  // Increase score
        } else {                                // If they don't
            p.currentResult--;                  // Decrease the score
        }
        // Create a log of this event
        Voted(id,  supportsProposal, msg.sender, justificationText);
    }

    /**
     * @dev Try to execute proposal
     * @param id Proposal identifier
     * @param transactionBytecode Transaction data
     */
    function executeProposal(
        uint256 id,
        bytes   transactionBytecode
    )
        onlyMembers
    {
        Proposal p = proposals[id];
        /* Check if the proposal can be executed:
           - Has the voting deadline arrived?
           - Has it been already executed or is it being executed?
           - Does the transaction code match the proposal?
           - Has a minimum quorum?
        */

        if (now < p.votingDeadline
            || p.executed
            || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode)
            || p.numberOfVotes < minimumQuorum)
            throw;

        /* execute result */
        /* If difference between support and opposition is larger than margin */
        if (p.currentResult > majorityMargin) {
            // Avoid recursive calling

            p.executed = true;
            if (!p.recipient.call.value(p.amount)(transactionBytecode))
                throw;

            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
        // Fire Events
        ProposalTallied(id, p.numberOfVotes, p.proposalPassed);
    }
}

library CreatorCongress {
    function create(uint256 minimumQuorumForProposals, uint256 minutesForDebate, int256 marginOfVotesForMajority, address congressLeader) returns (Congress)
    { return new Congress(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority, congressLeader); }

    function version() constant returns (string)
    { return "v0.6.3"; }

    function abi() constant returns (string)
    { return '[{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"proposals","outputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"},{"name":"description","type":"string"},{"name":"votingDeadline","type":"uint256"},{"name":"executed","type":"bool"},{"name":"proposalPassed","type":"bool"},{"name":"numberOfVotes","type":"uint256"},{"name":"currentResult","type":"int256"},{"name":"proposalHash","type":"bytes32"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"targetMember","type":"address"}],"name":"removeMember","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"id","type":"uint256"},{"name":"transactionBytecode","type":"bytes"}],"name":"executeProposal","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"memberId","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"numProposals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hammer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"members","outputs":[{"name":"member","type":"address"},{"name":"name","type":"string"},{"name":"memberSince","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"debatingPeriodInMinutes","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"minimumQuorum","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"destroy","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"},{"name":"_token","type":"address"},{"name":"_extraData","type":"bytes"}],"name":"receiveApproval","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"majorityMargin","outputs":[{"name":"","type":"int256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"jobDescription","type":"string"},{"name":"transactionBytecode","type":"bytes"}],"name":"newProposal","outputs":[{"name":"id","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"minimumQuorumForProposals","type":"uint256"},{"name":"minutesForDebate","type":"uint256"},{"name":"marginOfVotesForMajority","type":"int256"}],"name":"changeVotingRules","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"targetMember","type":"address"},{"name":"memberName","type":"string"}],"name":"addMember","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hammer","type":"address"}],"name":"setHammer","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"id","type":"uint256"},{"name":"supportsProposal","type":"bool"},{"name":"justificationText","type":"string"}],"name":"vote","outputs":[{"name":"vote","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"id","type":"uint256"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"transactionBytecode","type":"bytes"}],"name":"checkProposalCode","outputs":[{"name":"codeChecksOut","type":"bool"}],"payable":false,"type":"function"},{"inputs":[{"name":"minimumQuorumForProposals","type":"uint256"},{"name":"minutesForDebate","type":"uint256"},{"name":"marginOfVotesForMajority","type":"int256"},{"name":"congressLeader","type":"address"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposal","type":"uint256"},{"indexed":true,"name":"recipient","type":"address"},{"indexed":true,"name":"amount","type":"uint256"},{"indexed":false,"name":"description","type":"string"}],"name":"ProposalAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposal","type":"uint256"},{"indexed":true,"name":"position","type":"bool"},{"indexed":true,"name":"voter","type":"address"},{"indexed":false,"name":"justification","type":"string"}],"name":"Voted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposal","type":"uint256"},{"indexed":true,"name":"quorum","type":"uint256"},{"indexed":true,"name":"active","type":"bool"}],"name":"ProposalTallied","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"member","type":"address"},{"indexed":true,"name":"isMember","type":"bool"}],"name":"MembershipChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"minimumQuorum","type":"uint256"},{"indexed":true,"name":"debatingPeriodInMinutes","type":"uint256"},{"indexed":true,"name":"majorityMargin","type":"int256"}],"name":"ChangeOfRules","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":true,"name":"amount","type":"uint256"}],"name":"ReceivedEther","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"value","type":"uint256"},{"indexed":true,"name":"token","type":"address"},{"indexed":false,"name":"extraData","type":"bytes"}],"name":"ReceivedTokens","type":"event"}]'; }
}

/**
 * @title Builder based contract
 */
contract Builder is Object {
    /**
     * @dev this event emitted for every builded contract
     */
    event Builded(address indexed client, address indexed instance);

    /* Addresses builded contracts at sender */
    mapping(address => address[]) public getContractsOf;

    /**
     * @dev Get last address
     * @return last address contract
     */
    function getLastContract() constant returns (address) {
        var sender_contracts = getContractsOf[msg.sender];
        return sender_contracts[sender_contracts.length - 1];
    }

    /* Building beneficiary */
    address public beneficiary;

    /**
     * @dev Set beneficiary
     * @param _beneficiary is address of beneficiary
     */
    function setBeneficiary(address _beneficiary) onlyOwner
    { beneficiary = _beneficiary; }

    /* Building cost  */
    uint public buildingCostWei;

    /**
     * @dev Set building cost
     * @param _buildingCostWei is cost
     */
    function setCost(uint _buildingCostWei) onlyOwner
    { buildingCostWei = _buildingCostWei; }

    /* Security check report */
    string public securityCheckURI;

    /**
     * @dev Set security check report URI
     * @param _uri is an URI to report
     */
    function setSecurityCheck(string _uri) onlyOwner
    { securityCheckURI = _uri; }
}

//
// AIRA Builder for Congress contract
//
contract BuilderCongress is Builder {
    /**
     * @dev Run script creation contract
     * @return address new contract
     */
    function create(uint256 minimumQuorumForProposals,
                    uint256 minutesForDebate,
                    int256 marginOfVotesForMajority,
                    address congressLeader,
                    address _client) payable returns (address) {
        if (buildingCostWei > 0 && beneficiary != 0) {
            // Too low value
            if (msg.value < buildingCostWei) throw;
            // Beneficiary send
            if (!beneficiary.send(buildingCostWei)) throw;
            // Refund
            if (msg.value > buildingCostWei) {
                if (!msg.sender.send(msg.value - buildingCostWei)) throw;
            }
        } else {
            // Refund all
            if (msg.value > 0) {
                if (!msg.sender.send(msg.value)) throw;
            }
        }

        if (_client == 0)
            _client = msg.sender;

        if (congressLeader == 0)
            congressLeader = _client;

        var inst = CreatorCongress.create(minimumQuorumForProposals,
                                          minutesForDebate,
                                          marginOfVotesForMajority,
                                          congressLeader);
        inst.setOwner(_client);
        inst.setHammer(_client);
        getContractsOf[_client].push(inst);
        Builded(_client, inst);
        return inst;
    }
function() payable external {
	revert();
}
}
