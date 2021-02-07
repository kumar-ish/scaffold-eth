pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  uint256 public deadline = now + 30 seconds;
  uint256 public constant threshold = 1 ether;
  mapping (address => uint256) public balances;
  event Stake(address indexed _sender, uint256 _stakeAmount);

  modifier notCompleted {
    require(!exampleExternalContract.completed(), "Contract is completed; sorry!");
    _;
  }

  modifier deadlinePassed {
    require(timeLeft() == 0, "Deadline hasn't passed yet; sorry!");
    _;
  }

  function timeLeft() public view returns (uint256) {
    if (deadline <= now) {
      return 0;
    }
    return deadline - now;
  }

  function stake() public payable {
    require(timeLeft() > 0, "Deadline has passed; sorry!");

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public payable notCompleted deadlinePassed {
    require(address(this).balance >= threshold, "Staking balance below the threshold; sorry!");
    
    exampleExternalContract.complete{value: address(this).balance}();
  }
  
  function withdraw(address payable _withdrawTo) public notCompleted deadlinePassed {
    require(address(this).balance < threshold, "Your balance is above the threshold so you can't withdraw; sorry!");
    require(msg.sender == _withdrawTo);

    balances[_withdrawTo] = 0;
    _withdrawTo.call.value(balances[_withdrawTo])("");
  }
}
