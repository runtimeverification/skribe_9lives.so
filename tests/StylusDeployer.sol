
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";

contract StylusDeployer is Test {

    function deployWasm(string memory path) external returns (address) {
        bytes memory bytecode = vm.readFileBinary(path);
        require(bytecode.length > 0, "empty wasm file");

        bytes memory initCode = abi.encodePacked(
            hex"7f",                       // PUSH32
            bytes32(bytecode.length + 4),  // length(prefix + bytecode)
            hex"80",                       // DUP1
            hex"60",                       // PUSH1
            bytes1(uint8(42 + 1)),         // prelude + version
            hex"60",                       // PUSH1
            hex"00",
            hex"39",                       // CODECOPY
            hex"60",                       // PUSH1
            hex"00",
            hex"f3",                       // RETURN
            hex"00",                       // <version>
            hex"eff000",                   // <Stylus discriminant>
            hex"00",                       // <compression level>
            bytecode
        );
        require(initCode.length > 0, "empty init code");

        address newContractAddress;
        assembly ("memory-safe") {
            newContractAddress := create(0, add(initCode, 0x20), mload(initCode))
        }
        require(newContractAddress != address(0), "CREATE_FAILED");
        return newContractAddress;
    }

}