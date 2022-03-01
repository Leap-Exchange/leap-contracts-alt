// SPDX-License-Identifier: MIT
// pragma solidity >0.6.11 <0.8.12;
pragma solidity ^0.8.0;

// import 'arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol';
import '@eth-optimism/contracts/L1/messaging/IL1CrossDomainMessenger.sol';
import './utils/Data.sol';

// This contract gets deployed on L1

contract Destination {
  using SafeMath for uint256;
  address owner;
  address L2_SOURCE_CONTRACT;

  constructor(address L2SourceAddress){
    // L2SourceAddr = L2SourceAddress;
    L2_SOURCE_CONTRACT = L2SourceAddress;
    owner = msg.sender;
  }

  // function sendMsgArbitrumDest(){
  //  IL1CrossDomainMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1).sendMessage(L2_SOURCE_CONTRACT,  abi.encodeWithSignature(
  //               "processClaims()", //[TODO]: change later maybe?
  //               myFunctionParam
  //           ));

  // }

  function sendMsgToOptimismSrc(bytes32[] memory) public{
    require(msg.sender == 0x4361d0F75A0186C05f971c566dC6bEa5957483fD, "not called from messenger"); // check if called by Proxy__OVM_L1CrossDomainMessenger
    IL1CrossDomainMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1).sendMessage(
      L2_SOURCE_CONTRACT,
      abi.encodeWithSignature(
        "processClaims(struct[])", //[TODO]: change later maybe?
        myFunctionParam
      ),
      100000 // [TODO]: gas limit change later?
      );

  }

}
