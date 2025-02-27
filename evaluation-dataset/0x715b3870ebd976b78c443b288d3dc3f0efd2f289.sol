pragma solidity ^0.4.18;

contract SafeMath {
  function mulSafe(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
       return 0;
     }
     uint256 c = a * b;
     assert(c / a == b);
     return c;
   }

  function divSafe(uint256 a, uint256 b) internal pure returns (uint256) {
     uint256 c = a / b;
     return c;
  }

  function subSafe(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
     return a - b;
   }

  function addSafe(uint256 a, uint256 b) internal pure returns (uint256) {
     uint256 c = a + b;
    assert(c >= a);
     return c;
   }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Constructor() public { owner = msg.sender; }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract ERC20 {
   uint256 public totalSupply;
   function balanceOf(address who) public view returns (uint256);
   function transfer(address to, uint256 value) public returns (bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
   function allowance(address owner, address spender) public view returns (uint256);
   function transferFrom(address from, address to, uint256 value) public returns (bool);
   function approve(address spender, uint256 value) public returns (bool);
   event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC223 {
    function transfer(address to, uint value, bytes data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract StandardToken is ERC20, ERC223, SafeMath, Owned {

   mapping(address => uint256) balances;
   mapping (address => mapping (address => uint256)) internal allowed;

   function transfer(address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     balances[msg.sender] = subSafe(balances[msg.sender], _value);
     balances[_to] = addSafe(balances[_to], _value);
     Transfer(msg.sender, _to, _value);
     return true;
   }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
   }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);

    balances[_from] = subSafe(balances[_from], _value);
     balances[_to] = addSafe(balances[_to], _value);
     allowed[_from][msg.sender] = subSafe(allowed[_from][msg.sender], _value);
    Transfer(_from, _to, _value);
     return true;
   }

   function approve(address _spender, uint256 _value) public returns (bool) {
     allowed[msg.sender][_spender] = _value;
     Approval(msg.sender, _spender, _value);
     return true;
   }

  function allowance(address _owner, address _spender) public view returns (uint256) {
     return allowed[_owner][_spender];
   }

   function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
     allowed[msg.sender][_spender] = addSafe(allowed[msg.sender][_spender], _addedValue);
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
     return true;
   }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
     uint oldValue = allowed[msg.sender][_spender];
     if (_subtractedValue > oldValue) {
       allowed[msg.sender][_spender] = 0;
     } else {
       allowed[msg.sender][_spender] = subSafe(oldValue, _subtractedValue);
    }
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
     return true;
   }

    function transfer(address _to, uint _value, bytes _data) public {
        require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = subSafe(balances[msg.sender], _value);
        balances[_to] = addSafe(balances[_to], _value);
        Transfer(msg.sender, _to, _value, _data);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

}

contract TAXToken is StandardToken {
   string public name = 'TAXToken';
   string public symbol = 'TAX';
   uint public decimals = 8;
   uint public INITIAL_SUPPLY = 1000000000;

   uint public _frozeAmount = 400000000;
   uint public _firstUnlockAmmount = 50000000;
   uint public _secondUnlockAmmount = 50000000;
   uint _firstUnlockTime;
   uint _secondUnlockTime;

   function TAXToken() public {
     totalSupply = 500000000 * 10 ** uint256(decimals);   // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
     balances[msg.sender] = totalSupply;
     _firstUnlockTime  = now + 31536000;
     _secondUnlockTime = now + 63072000;
   }

   function releaseFirstUnlock() public onlyOwner returns (bool success){
        require(now >= _firstUnlockTime);
        require(_firstUnlockAmmount > 0);
        balances[msg.sender] = addSafe(balances[msg.sender], _firstUnlockAmmount);
        _firstUnlockAmmount = 0;
        Transfer(address(0), msg.sender, _firstUnlockAmmount);
        return true;
    }

    function releaseSecondUnlock() public onlyOwner returns (bool success){
        require(now >= _secondUnlockTime);
        require(_secondUnlockAmmount > 0);
        balances[msg.sender] = addSafe(balances[msg.sender], _secondUnlockAmmount);
        _secondUnlockAmmount = 0;
        Transfer(address(0), msg.sender, _secondUnlockAmmount);
        return true;
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
