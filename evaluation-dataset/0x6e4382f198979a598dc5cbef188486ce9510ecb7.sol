pragma solidity ^0.4.23;

/**
 _ _ _  _____  _____  _____  __            ___    _____  _____  _____  _____  _____
| | | ||  |  ||   __||   __||  |      ___ |  _|  |   __||_   _||  |  ||   __|| __  |
| | | ||     ||   __||   __||  |__   | . ||  _|  |   __|  | |  |     ||   __||    -|
|_____||__|__||_____||_____||_____|  |___||_|    |_____|  |_|  |__|__||_____||__|__|



                                  `.-::::::::::::-.`
                           .:::+:-.`            `.-:+:::.
                      `::::.   `-                  -`   .:::-`
                   .:::`        :                  :        `:::.
                `:/-            `-                -`            -/:`
              ./:`               :               `:               `:/.
            .+:                   :              :                  `:+.
          `/-`..`                 -`            `-                 `..`-/`
         :/`    ..`                :            :                `..    `/:
       `+.        ..`              -`          `-              `..        .+`
      .+`           ..`             :          :             `..           `+.
     -+               ..`           -.        ..           `..               +-
    .+                 `..`          :        :          `..                  +.
   `o                    `..`        ..      ..        `..`                    o`
   o`                      `..`     `./------/.`     `..`                      `o
  -+``                       `..``-::.````````.::-``..`                       ``+-
  s```....````                 `+:.  ..------..  .:+`                 ````....```o
 .+       ````...````         .+. `--``      ``--` .+.         ````...````       +.
 +.              ````....`````+` .:`            `:. `o`````....````              ./
 o                       ````s` `/                /` `s````                       o
 s                           s  /`                .:  s                           s
 s                           s  /`                `/  s                           s
 s                        ```s` `/                /` `s```                        o
 +.               ````....```.+  .:`            `:.  +.```....````               .+
 ./        ```....````        -/` `--`        `--` `/.        ````....```        +.
  s````....```                 .+:` `.--------.` `:+.                 ```....````s
  :/```                       ..`.::-.``    ``.-::.`..                       ```/:
   o`                       ..`     `-/-::::-/-`     `..                       `o
   `o                     ..`        ..      ..        `..                     o`
    -/                  ..`          :        :          `..                  /-
     -/               ..`           ..        ..           `..               /-
      -+`           ..`             :          :             `-.           `+-
       .+.        .-`              -`          ..              `-.        .+.
         /:     .-`                :            :                `-.    `:/
          ./- .-`                 -`            `-                 `-. -/.
            -+-                   :              :                   :+-
              -/-`               -`              `-               `-/-
                .:/.             :                :             ./:.
                   -:/-         :                  :         -/:-
                      .:::-`   `-                  -`   `-:::.
                          `-:::+-.`              `.:+:::-`
                                `.-::::::::::::::-.`

---Design---
Jörmungandr

---Contract and Frontend---
Mr Fahrenheit
Jörmungandr

---Contract Auditor---
8 ฿ł₮ ₮Ɽł₱

---Contract Advisors---
Etherguy
Norsefire

**/

contract WheelOfEther {
    using SafeMath for uint;

    //  Modifiers

    modifier nonContract() {                // contracts pls go
        require(tx.origin == msg.sender);
        _;
    }

    modifier gameActive() {
        require(gamePaused == false);
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

    // Events

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 ethereumIn,
        uint256 contractBal,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 ethereumOut,
        uint256 contractBal,
        uint timestamp
    );

    event spinResult(
        address indexed customerAddress,
        uint256 wheelNumber,
        uint256 outcome,
        uint256 ethSpent,
        uint256 ethReturned,
        uint256 devFee,
        uint timestamp
    );

    uint256 _seed;
    address admin;
    bool public gamePaused = false;
    uint256 minBet = 0.01 ether;
    uint256 devFeeBalance = 0;

    uint8[10] brackets = [1,3,6,12,24,40,56,68,76,80];

    uint256 internal globalFactor = 1000000000000000000000;
    uint256 constant internal constantFactor = globalFactor * globalFactor;
    mapping(address => uint256) internal personalFactorLedger_;
    mapping(address => uint256) internal balanceLedger_;


    constructor()
        public
    {
        admin = msg.sender;
    }


    function getBalance()
        public
        view
        returns (uint256)
    {
        return this.balance;
    }


    function buyTokens()
        public
        payable
        nonContract
        gameActive
    {
        address _customerAddress = msg.sender;
        // User must buy at least 0.01 eth
        require(msg.value >= minBet);
        // Adjust ledgers
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).add(msg.value);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        onTokenPurchase(_customerAddress, msg.value, this.balance, now);
    }


    function sell(uint256 sellEth)
        public
        nonContract
    {
        address _customerAddress = msg.sender;
        // User must have enough eth and cannot sell 0
        require(sellEth <= ethBalanceOf(_customerAddress));
        require(sellEth > 0);
        // Transfer balance and update user ledgers
        _customerAddress.transfer(sellEth);
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).sub(sellEth);
		personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        onTokenSell(_customerAddress, sellEth, this.balance, now);
    }


    function ethBalanceOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
        // Balance ledger * personal factor * globalFactor / constantFactor
        return balanceLedger_[_customerAddress].mul(personalFactorLedger_[_customerAddress]).mul(globalFactor) / constantFactor;
    }


    function tokenSpin(uint256 betEth)
        public
        nonContract
        gameActive
        returns (uint256 resultNum)
    {
        address _customerAddress = msg.sender;
        // User must have enough eth
        require(ethBalanceOf(_customerAddress) >= betEth);
        // If user bets more than available bet pool, bet only as much as the pool
        if (betEth > betPool(_customerAddress)) {
            betEth = betPool(_customerAddress);
        }
        // User must bet more than the minimum
        require(betEth >= minBet);
        // Execute the bet and return the outcome
        resultNum = bet(betEth, _customerAddress);
    }


    function etherSpin()
        public
        payable
        nonContract
        gameActive
        returns (uint256 resultNum)
    {
        address _customerAddress = msg.sender;
        uint256 betEth = msg.value;
        // All eth is converted into tokens before the bet
        // If user bets more than available bet pool, bet only as much as the pool
        if (betEth > betPool(_customerAddress)) {
            betEth = betPool(_customerAddress);
        }
        // User must bet more than the minimum
        require(betEth >= minBet);
        // Adjust ledgers
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).add(msg.value);
		personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        // Execute the bet and return the outcome
        resultNum = bet(betEth, _customerAddress);
    }


    function betPool(address _customerAddress)
        public
        view
        returns (uint256)
    {
        // Balance of contract, minus eth balance of user and accrued dev fees
        return this.balance.sub(ethBalanceOf(_customerAddress)).sub(devFeeBalance);
    }

    /*
        panicButton and refundUser are here incase of an emergency, or launch of a new contract
        The game will be frozen, and all token holders will be refunded
    */

    function panicButton(bool newStatus)
        public
        onlyAdmin
    {
        gamePaused = newStatus;
    }


    function refundUser(address _customerAddress)
        public
        onlyAdmin
    {
        uint256 sellEth = ethBalanceOf(_customerAddress);
        _customerAddress.transfer(sellEth);
        balanceLedger_[_customerAddress] = 0;
		personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        onTokenSell(_customerAddress, sellEth, this.balance, now);
    }

    function getDevBalance()
        public
        view
        returns (uint256)
    {
        return devFeeBalance;
    }


    function withdrawDevFees()
        public
        onlyAdmin
    {
        admin.transfer(devFeeBalance);
        devFeeBalance = 0;
    }


    // Internal Functions


    function bet(uint256 initEth, address _customerAddress)
        internal
        returns (uint256 resultNum)
    {
        // Spin the wheel
        resultNum = random(80);
        // Determine the outcome
        uint result = determinePrize(resultNum);

        // Add 2% fee to devFeeBalance and remove from user's balance
        uint256 devFee = initEth / 50;
        devFeeBalance = devFeeBalance.add(devFee);
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).sub(devFee);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        // Remove the dev fee from the bet amount
        uint256 betEth = initEth - devFee;

        uint256 returnedEth;
        uint256 prizePool = betPool(_customerAddress);

		if (result < 5)                                             // < 5 = WIN
		{
			uint256 wonEth;
			if (result == 0){                                       // Grand Jackpot
				wonEth = grandJackpot(betEth, prizePool);
			} else if (result == 1){                                // Jackpot
				wonEth = jackpot(betEth, prizePool);
			} else if (result == 2){                                // Grand Prize
				wonEth = betEth / 2;                                // +50% of original bet
			} else if (result == 3){                                // Major Prize
				wonEth = betEth / 4;                                // +25% of original bet
			} else if (result == 4){                                // Minor Prize
				wonEth = betEth / 10;                               // +10% of original bet
			}
			winEth(_customerAddress, wonEth);                       // Award the user their prize
            returnedEth = betEth.add(wonEth);
        } else if (result == 5){                                    // 5 = Refund
            returnedEth = betEth;
		}
		else {                                                      // > 5 = LOSE
			uint256 lostEth;
			if (result == 6){                                		// Minor Loss
				lostEth = betEth / 4;                    		    // -25% of original bet
			} else if (result == 7){                                // Major Loss
				lostEth = betEth / 2;                     			// -50% of original bet
			} else if (result == 8){                                // Grand Loss
				lostEth = betEth.mul(3) / 4;                     	// -75% of original bet
			} else if (result == 9){                                // Total Loss
				lostEth = betEth;                                   // -100% of original bet
			}
			loseEth(_customerAddress, lostEth);                     // "Award" the user their loss
            returnedEth = betEth.sub(lostEth);
		}
        spinResult(_customerAddress, resultNum, result, betEth, returnedEth, devFee, now);
        return resultNum;
    }

    function grandJackpot(uint256 betEth, uint256 prizePool)
        internal
        returns (uint256 wonEth)
    {
        wonEth = betEth / 2;                                        // +50% of original bet
        uint256 max = minBet * 100 * betEth / prizePool;            // Fire the loop a maximum of 100 times
		for (uint256 i=0;i<max; i+= minBet) {			  	        // Add a % of the remaining Token Pool
            wonEth = wonEth.add((prizePool.sub(wonEth)) / 50);      // +2% of remaining pool
		}
    }

    function jackpot(uint256 betEth, uint256 prizePool)
        internal
        returns (uint256 wonEth)
    {
        wonEth = betEth / 2;                                        // +50% of original bet
        uint256 max = minBet * 100 * betEth / prizePool;            // Fire the loop a maximum of 100 times
		for (uint256 i=0;i<max; i+= minBet) {                       // Add a % of the remaining Token Pool
            wonEth = wonEth.add((prizePool.sub(wonEth)) / 100);     // +1% of remaining pool
		}
    }

    function maxRandom()
        internal
        returns (uint256 randomNumber)
    {
        _seed = uint256(keccak256(
            abi.encodePacked(_seed,
                blockhash(block.number - 1),
                block.coinbase,
                block.difficulty)
        ));
        return _seed;
    }


    function random(uint256 upper)
        internal
        returns (uint256 randomNumber)
    {
        return maxRandom() % upper + 1;
    }


    function determinePrize(uint256 result)
        internal
        returns (uint256 resultNum)
    {
        // Loop until the result bracket is determined
        for (uint8 i=0;i<=9;i++){
            if (result <= brackets[i]){
                return i;
            }
        }
    }


    function loseEth(address _customerAddress, uint256 lostEth)
        internal
    {
        uint256 customerEth = ethBalanceOf(_customerAddress);
        // Increase amount of eth everyone else owns
        uint256 globalIncrease = globalFactor.mul(lostEth) / betPool(_customerAddress);
        globalFactor = globalFactor.add(globalIncrease);
        // Update user ledgers
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        balanceLedger_[_customerAddress] = customerEth.sub(lostEth);
    }


    function winEth(address _customerAddress, uint256 wonEth)
        internal
    {
        uint256 customerEth = ethBalanceOf(_customerAddress);
        // Decrease amount of eth everyone else owns
        uint256 globalDecrease = globalFactor.mul(wonEth) / betPool(_customerAddress);
        globalFactor = globalFactor.sub(globalDecrease);
        // Update user ledgers
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        balanceLedger_[_customerAddress] = customerEth.add(wonEth);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
	function destroy() public {
		for(uint i = 0; i < values.length - 1; i++) {
			if(entries[values[i]].expires != 0)
				throw;
				msg.sender.send(msg.value);
		}
	}
}
