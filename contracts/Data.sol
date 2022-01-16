// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Data{
  struct TransferData { 
    address tokenAddress;
    address destination;
    uint256 amount;
    uint256 fee;
    uint256 startTime;
    uint256 feeRampup;
    uint256 nonce;
  }

  struct RewardData { 
		bytes32 transferDataHash;
    address tokenAddress;
    address claimer;
    uint256 fee;
  }
}
