pragma solidity ^0.4.24;

interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountedChildren(address _owner,uint256 _tokenId, address _childAddress) external view returns(uint256[]);
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedAvatars(address _owner) external view returns(uint256[] _avatars);
  function unmount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
  function mount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
}

contract AvatarOperator is Ownable {

  // every user can own avatar count
  uint8 public PER_USER_MAX_AVATAR_COUNT = 1;

  event AvatarCreate(address indexed _owner, uint256 tokenId);

  AvatarService internal avatarService;
  address internal avatarAddress;

  modifier nameValid(string _name){
    bytes memory nameBytes = bytes(_name);
    require(nameBytes.length > 0);
    require(nameBytes.length < 16);
    for(uint8 i = 0; i < nameBytes.length; ++i) {
      uint8 asc = uint8(nameBytes[i]);
      require (
        asc == 95 || (asc >= 48 && asc <= 57) || (asc >= 65 && asc <= 90) || (asc >= 97 && asc <= 122), "Invalid name");
    }
    _;
  }

  function setMaxAvatarNumber(uint8 _maxNumber) external onlyOwner {
    PER_USER_MAX_AVATAR_COUNT = _maxNumber;
  }

  function injectAvatarService(address _addr) external onlyOwner {
    avatarService = AvatarService(_addr);
    avatarAddress = _addr;
  }

  function updateAvatarInfo(uint256 _tokenId, string _name, uint256 _dna) external nameValid(_name){
    avatarService.updateAvatarInfo(msg.sender, _tokenId, _name, _dna);
  }

  function createAvatar(string _name, uint256 _dna) external nameValid(_name) returns (uint256 _tokenId){
    require(ERC721(avatarAddress).balanceOf(msg.sender) < PER_USER_MAX_AVATAR_COUNT, "overflow");
    _tokenId = avatarService.createAvatar(msg.sender, _name, _dna);
    emit AvatarCreate(msg.sender, _tokenId);
  }

  function getMountedChildren(uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]){
    return avatarService.getMountedChildren(msg.sender, _tokenId, _avatarItemAddress);
  }

  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna) {
    return avatarService.getAvatarInfo(_tokenId);
  }

  function getOwnedAvatars() external view returns(uint256[] _tokenIds) {
    return avatarService.getOwnedAvatars(msg.sender);
  }

  function handleChildren(
	address _childContract,
	uint256[] _unmountChildren, // array of unmount child ids
	uint256[] _mountChildren,   // array of mount child ids
	uint256 _avatarId)           // above ids from which avatar
	external {
	require(_childContract != address(0), "child address error");
	avatarService.unmount(msg.sender, _childContract, _unmountChildren, _avatarId);
	avatarService.mount(msg.sender, _childContract, _mountChildren, _avatarId);
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
