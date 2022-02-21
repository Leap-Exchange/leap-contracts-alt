// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Data{
  struct TransferData { 
    address srcTokenAddress;
    address destTokenAddress;
    address destination;
    uint256 amount;
    uint256 fee;
    uint256 startTime;
    uint256 feeRampup;
  }

  struct RewardData { 
		bytes32 transferDataHash;
    address srcTokenAddress;
    address claimer;
    uint256 fee;
  }
}
