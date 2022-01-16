// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Data.sol';

// [TODO]
// import openzeppelin ERC20 Interface so we can use ERC20 token functions

contract Destination {
  address public owner = msg.sender;
  // transferOwners: (transferData, transferID) => address owner
  // might change state map implementation in the future
  // mapping(struct => mapping(uint => address)) public transferOwners; -> This does not work,
  // since maps cannot utilise complex objects such as structs as keys, instead,
  // the the arguments in TransferData will be concatenated and turned into bytes 
  // before indexing transferOwners.
  mapping(bytes => mapping(uint => address)) public transferOwners;
  mapping(bytes32 => bool) public claimedTransferHashes;
  uint256 public transferCount; 
  bytes32[] rewardHashOnionHistoryList;


  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function claim(Data.TransferData memory transferData) public {
    transferHash = abi.encode(transferData);
    require(!clainedTransferHashes(transferHash));
    IERC20(transferData.tokenAddress).transferFrom(msg.sender, address(this), amountPlusFee);
    claimedTransferHashes[] = true;
    uint256 currentTime = block.timestamp;
    rewardData = Data.RewardData(transferHash, transferData.tokeAddress, transferData.destination, getLPFee(transferData, currentTime));
    bytes32 rewardHashOnion = abi.encode(rewardHashOnion, rewardData);
    transferCount++;

    if (transferCount % 100 == 0){
      rewardHashOnionHistoryList.push(rewardHashOnion);
    }

  }

  function getLPFee(Data.TransferData memory transfer, uint256 currentTime) public pure returns(uint256) {
    if (currentTime < transfer.startTime){
      return 0;
    }
    else if (currentTime >= transfer.startTime + transfer.feeRampup){
      return transfer.fee;
    }
    else{
      // Note: this clause is unreachable if feeRampup == 0
      // [TODO] Implement int divide '//' operator in solidity for return statement below
      return uint256(transfer.fee * (currentTime - transfer.startTime)) / transfer.feeRampup; 
    }
    
  }

  function declareNewHashChainHead(){}

  function changeOwner(Data.TransferData memory transferData, uint transferID, address newOwner) public { }

  function buy(Data.TransferData memory transferData, uint transferID) public {}



}
