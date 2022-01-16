// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Data.sol';

// [TODO]
// import openzeppelin ERC20 Interface so we can use ERC20 token functions

contract Source {
  address public owner = msg.sender;
  uint public nextTransferID;
  // [TODO]: what's this?
  uint public CONTRACT_FEE_BASIS_POINTS;
  mapping(bytes32 => bool) public validTransferHashes;
  bytes32 public processedRewardHashOnion;
  mapping(bytes32 => bool) public knownHashOnions;


  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  constructor(){
    nextTransferID = 0;
    CONTRACT_FEE_BASIS_POINTS = 5;
  }

  event TransferInitiated(Data.TransferData transfer, uint256 transferID);

  function transfer(Data.TransferData memory transferData) public payable {
    // improve hashing implementation - optimize for least gas usage. For now, the following will have to do
    bytes32 transferHash = keccak256(abi.encode(transferData));
    require(!validTransferHashes[transferHash]);
    uint256 amountPlusFee = uint(transferData.amount * (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;
    if (transferData.tokenAddress != address(0))
    {
      IERC20(transferData.tokenAddress).transferFrom(msg.sender, address(this), amountPlusFee);
    } 
   else{
      // Transfer ether here
      require(msg.value == amountPlusFee, 'insufficient ether provided');
    }
    validTransferHashes[transferHash] = true;
    emit TransferInitiated(transferData, nextTransferID); 
 }

  function processClaims(Data.RewardData[] memory rewardData) public{


  }

}
