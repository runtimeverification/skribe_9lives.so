
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";

import { CtorArgs, INineLivesTrading } from "../src/INineLivesTrading.sol";

import { StylusDeployer } from "./StylusDeployer.sol";

import { TestERC20 } from "./TestERC20.sol";

interface ISkribeTrading is INineLivesTrading {
    
    function isSkribe() external returns (bool);
    
    function ctorSkribe(
        bytes8[] memory outcomes,
        address oracle,
        uint64 timeStart,
        uint64 timeEnding,
        address feeRecipient,
        bool shouldBufferTime,
        uint64 feeCreator,
        uint64 feeLp,
        uint64 feeMinter,
        uint64 feeReferrer,
        uint256 seedLiq
    ) external;

    function mintSkribe(bytes8 outcome, uint256 value, address recipient) external returns (uint256);

    function payoffSkribe(bytes8 outcomeId, uint256 amt, address recipient) external returns (uint256);

    function decideSkribe(bytes8 outcome) external returns (uint256);

}

struct ActionAmountPurchased {
    uint256 fusdcAmt;
    bool outcome;
}

contract TestSkribeEndToEnd is Test, TestERC20 {

    ISkribeTrading dppm;

    function setUp() public {
        StylusDeployer deployer = new StylusDeployer();
        dppm = ISkribeTrading(deployer.deployWasm("contract-trading-dppm-skribe.wasm"));
    }

    function testIsSkribeFlag() public {
        assert(dppm.isSkribe());
    }

    function test_end_to_end_intense(
        bytes8 outcomeId1,
        bytes8 outcomeId2,
        bool outcomeWinner,
        ActionAmountPurchased[] memory purchaseInt1
    ) external {
        uint256 timeStart = block.timestamp + 1;
        uint256 timeEnding = timeStart + 100;
        uint256 initLiq = 2e6;

        vm.assume(outcomeId1 != 0x00000000);
        vm.assume(outcomeId2 != 0x00000000);
        vm.assume(outcomeId1 != outcomeId2);

        // validate actions
        vm.assume(0 < purchaseInt1.length && purchaseInt1.length < 1000);

        for (uint256 i = 0; i < purchaseInt1.length; i++) {
            // map fusdc amounts to a reasonable range
            purchaseInt1[i].fusdcAmt = purchaseInt1[i].fusdcAmt % 100000000000 + 1;
        }

        _mint(address(this), type(uint256).max);
        _transfer(address(this), address(dppm), initLiq);
        _approve(address(this), address(dppm), type(uint256).max);

        bytes8[] memory outcomes =  new bytes8[](2);
        outcomes[0] = outcomeId1;
        outcomes[1] = outcomeId2;
        
        dppm.ctorSkribe(
            outcomes,
            address(this),
            uint64(timeStart),
            uint64(timeEnding),
            address(this),
            false,
            0,
            0,
            0,
            0,
            initLiq
        );
        vm.warp(timeStart);

        uint256 fusdcVested = 0;
        uint256 fusdcSpent1 = 0;
        uint256 fusdcSpent2 = 0;
        uint256 share1Received = 0;
        uint256 share2Received = 0;

        for (uint256 i = 0; i < purchaseInt1.length; i++) {
            uint256 fusdcAmt = purchaseInt1[i].fusdcAmt;
            
            fusdcVested += fusdcAmt;

            uint256 s = dppm.mintSkribe(
                purchaseInt1[i].outcome ? outcomeId1 : outcomeId2,
                fusdcAmt,
                address(this)
            );

            if( purchaseInt1[i].outcome ){
                fusdcSpent1 += s;
                share1Received += s;
            } else {
                fusdcSpent2 += s;
                share2Received += s;    
            }
        }

        // if( fusdcSpent1 <= 0 && fusdcSpent2 > 0 ){
        //     revert("fusdc amount weird");
        // }

        bytes8 outcomeWinnerId = outcomeWinner ? outcomeId1     : outcomeId2;
        uint256 winningAmt     = outcomeWinner ? share1Received : share2Received;
        
        vm.warp(block.timestamp + 3);
        dppm.decideSkribe(outcomeWinnerId);
        
        uint256 retAmt = dppm.payoffSkribe(outcomeWinnerId, winningAmt, address(this));

        // vm.assertLe(retAmt, fusdcVested, "failed");
    }
}
