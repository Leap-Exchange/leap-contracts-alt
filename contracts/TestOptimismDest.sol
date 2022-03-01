// SPDX-License-Identifier: MIT
// pragma solidity >0.6.11 <0.8.12;
pragma solidity >0.6.11 <0.8.12;
// pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@eth-optimism/contracts/L2/messaging/IL2CrossDomainMessenger.sol';
import './utils/Data.sol';

contract Destination {
  using SafeMath for uint256;

  address public owner;
  address public L2SourceAddr;
  mapping(bytes32 => bool) claimedTransferHashes;
  uint256 public transferCount; 
  bytes32[] public rewardHashOnionHistoryList;
  uint256 public lastSourceHeadPosition;
  address public L1_MSGR;

  constructor(address L2SourceAddress, address L1Messenger) {
    L2SourceAddr = L2SourceAddress;
    L1_MSGR = L1Messenger;
    owner = msg.sender;
    transferCount = 0;
    rewardHashOnionHistoryList.push(keccak256(abi.encodePacked('0'))); // genesis hash
  }

  event TransferClaimed(bytes32 transferHash, uint256 transferNum);

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  // [TODO]: for UX, will probs remove ???
  // function claim(address srcTokenAddress, address destTokenAddress, address destination, uint256 amount, uint256 fee, uint256 startTime, uint256 feeRampup) public payable {
  //   Data.TransferData memory td = Data.TransferData(srcTokenAddress, destTokenAddress, destination, amount, fee, startTime, feeRampup);
  //   _claim(td);
  // }

  // Attempting to claim a transfer that does not exist on the source side will not benefit the claimer with any rewards. 
  // Call with caution :p
  function _claim(Data.TransferData memory transferData) public payable {
    // improve hashing implementation - optimize for least gas usage. For now, the following will have to do
    bytes32 transferHash = keccak256(abi.encodePacked(abi.encode(transferData), transferCount));
    require(!claimedTransferHashes[transferHash], 'this transfer has already been claimed');
    
    if (transferData.destTokenAddress != address(0))
    {
      IERC20(transferData.destTokenAddress).transferFrom(msg.sender, transferData.destination, transferData.amount);
      // IERC20(transferData.destTokenAddress).transferFrom(msg.sender, address(this), transferData.amount);
    } 
    else{
      // Transfer ether here
      // require(msg.value >= 0.001 ether, 'minimum ether required is 0.001 ether');
      require(msg.value == transferData.amount, 'insufficient ether provided');
      payable(transferData.destTokenAddress).transfer(transferData.amount);
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
    else if (currentTime >= transfer.startTime.add(transfer.feeRampup)){
      return transfer.fee;
    }
    else{
      // Note: this clause is unreachable if feeRampup == 0
      return transfer.fee.mul(currentTime.sub(transfer.startTime)).div(transfer.feeRampup);
    }
    
  }

  // For now the length of the reward onion list is 1 (for the sake of speeding up demo)
  function declareNewHashChainHead() public {
    require(rewardHashOnionHistoryList.length < lastSourceHeadPosition, 'There is no new hash onion, wait for transfers to be claimed');
    bytes32[] memory rewardList = new bytes32[](rewardHashOnionHistoryList.length - lastSourceHeadPosition);
    for(uint i = lastSourceHeadPosition; i <= rewardHashOnionHistoryList.length; i++){
      rewardList[i - lastSourceHeadPosition] = rewardList[i];
    }
    //temp vars
    bytes memory message = bytes('0');
    uint gas = 0;
    bytes32 calldataForL1 = abi.encodeWithSignature("sendMsgToOptimismSrc(bytes32[])", rewardHashOnionHistoryList);
    IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007).sendMessage(L1_MSGR, calldataForL1);
                
  }

  // only the owner of the contract can set the new address of the source contract - for now...
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

}
