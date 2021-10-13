/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.4.17;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TQToken {

    string public name;
    string public symbol;
    address public tqwatcher;
      
    event TQTransferFrom(address indexed sender, bytes32 indexed to1,bytes32 indexed to2, uint value);

    function TQToken(string _name, string _symbol,address _tqwatcher) public {
        name = _name;
        symbol = _symbol;
        tqwatcher = _tqwatcher;
    }
    /**
     * get contract address
     */
    function getAddress() public view returns (address) {
		return address(this);
	}
    /**
    *  Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    /**
     * transfer out by erc20
     * _from : erc20 contract address
     * _to: approve to  the address
     * _value: the balance want to transfer 
     */ 
    function tqTransferOut(address _from,address _to, uint _value) public {
         require(msg.sender == tqwatcher);
         ERC20(_from).approve(_to,_value);
    }
     /**
     * transfer to TQ by erc20 transferFrom
     * _from : erc20 contract address
     * _to: TQ address, which can get the balance from the contract
     * _value: the balance want to transfer 
     */ 
    function tqTransferFrom(address _from, string _to, uint _value) public onlyPayloadSize(3 * 32) {
        var to = getAddress();
        
        ERC20(_from).transferFrom(msg.sender,to,_value);
        var ( result1 , result2) = toBytes(_to);
        TQTransferFrom(_from, result1,result2, _value);
    }
    
    /**
     * convert the TQ address to bytes32 array 
     */
    function toBytes(string  source) internal pure returns(bytes32 result1 ,bytes32 result2){
       bytes memory value = bytes(source);
        if (value.length == 0) {
            return (0x0,0x0);
        }else if(value.length <= 32){
            assembly {
            result1 := mload(add(source, 32))
            result2 := 0x0
        }
        }else{
            bytes memory remain = substr(value,32);
            assembly {
            result1 := mload(add(source, 32))
            result2 := mload(add(remain, 32))
        }
        }
         
    }
     /**
     * sub  bytes  
     */
     function substr(bytes memory self, uint startIndex) internal pure returns (bytes memory) {
        require(startIndex <= self.length);
        uint len = self.length - startIndex;
        uint addr = dataPtr(self);
        return toBytes(addr + startIndex, len);
    }
     function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }
     function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }
     function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
}