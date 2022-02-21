// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './utils/Data.sol';

// temporary stand-in for an IBC contract
interface ICrossChainMessenger {
  function sendMsg(address contract_addr, bytes memory message, uint256 gas) external;

}

contract Destination {
  address public owner;
  address public L2SourceAddr;
  mapping(bytes32 => bool) claimedTransferHashes;
  uint256 public transferCount; 
  bytes32[] rewardHashOnionHistoryList;
  uint256 public lastSourceHeadPosition;

  constructor(address L2SourceAddress) {
    L2SourceAddr = L2SourceAddress;
    owner = msg.sender;
    transferCount = 0;
    rewardHashOnionHistoryList.push(keccak256(abi.encodePacked('0')));
  }

  event TransferClaimed(bytes32 transferHash, uint256 transferNum);

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  // Attempting to claim a transfer that does not exist on the source side will not benefit the claimer with any rewards. 
  // Call with caution :p
  function claim(Data.TransferData memory transferData) public payable{
    // improve hashing implementation - optimize for least gas usage. For now, the following will have to do
    bytes32 transferHash = keccak256(abi.encodePacked(abi.encode(transferData), transferCount));
    require(!claimedTransferHashes[transferHash], 'this transfer has already been claimed OR does not exist');
    
    if (transferData.destTokenAddress != address(0))
    {
      IERC20(transferData.destTokenAddress).transferFrom(msg.sender, transferData.destination, transferData.amount);
      // IERC20(transferData.destTokenAddress).transferFrom(msg.sender, address(this), transferData.amount);
    } 
   else{
      // Transfer ether here
      require(msg.value >= 0.001 ether, 'minimum ether required is 0.001 ether');
      require(msg.value == transferData.amount, 'insufficient ether provided');
      payable(transferData.destination).transfer(transferData.amount);
    }

    claimedTransferHashes[transferHash] = true;
    uint256 currentTime = block.timestamp;
    Data.RewardData memory rewardData = Data.RewardData(transferHash, transferData.destTokenAddress, transferData.destination, getLPFee(transferData, currentTime));
    bytes32 rewardHash = keccak256(abi.encode(rewardData));
    bytes32 rewardHashOnion = keccak256(abi.encode(rewardHash, rewardData));
    transferCount++;
    emit TransferClaimed(transferHash, transferCount);
    // Will need to address this update rate later
    // if (transferCount % 100 == 0){
    //   rewardHashOnionHistoryList.push(rewardHashOnion);
    // }

    rewardHashOnionHistoryList.push(rewardHashOnion);

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
      return transfer.fee * (currentTime - transfer.startTime) / transfer.feeRampup; 
    }
    
  }

  function declareNewHashChainHead() public {
    require(rewardHashOnionHistoryList.length < lastSourceHeadPosition, 'no new hash onion');
    bytes32[] memory rewardList = new bytes32[](rewardHashOnionHistoryList.length - lastSourceHeadPosition);
    for(uint i = lastSourceHeadPosition; i <= rewardHashOnionHistoryList.length; i++){
      rewardList[i - lastSourceHeadPosition] = rewardList[i];
    }
    //temp vars
    bytes memory message = bytes('0');
    uint gas = 0;
    ICrossChainMessenger(L2SourceAddr).sendMsg(L2SourceAddr, message, gas);
  }

  // only the owner of the contract can set he new address of the source contract - for now...
  function changeL2SourceAddr(address newAddress) public restricted{ 
    L2SourceAddr = newAddress;

  }

  // fallback function
  fallback() external{
  }

  // temporary - will probably not be included in the final implementation
  function changeOwner(address newOwner) public restricted { 
    require(owner != address(0), '0x0 address cannot be set as the owner!');
    require(owner != newOwner, 'this address is already the owner of the contract');
    owner = newOwner;
  }

  // function buy(Data.TransferData memory transferData, uint transferID) public {}


}
