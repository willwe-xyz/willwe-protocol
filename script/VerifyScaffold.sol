// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract ManuallyVerifyAll is Script {
    using stdJson for string;
    using Strings for uint256;

    function run(uint256 chainId) external {
        string memory apiKey = vm.envString("ETHERSCAN_API_KEY");
        string memory json =
            vm.readFile(string.concat("broadcast/Deploy.s.sol/", chainId.toString(), "/run-latest.json"));
        uint256 txCount = json.readUint(".transactions.length");

        // Iterate through all transactions
        for (uint256 i = 0; i < txCount; i++) {
            // Extract the contract address for each transaction
            address contractAddress =
                json.readAddress(string(abi.encodePacked(".transactions[", i.toString(), "].contractAddress")));

            // Verify the contract
            string[] memory cmd = new string[](5);
            cmd[0] = "forge";
            cmd[1] = "verify-contract";
            cmd[2] = vm.toString(contractAddress);
            cmd[3] = "src/MyContract.sol:MyContract"; // Contract path and name
            cmd[4] = apiKey;

            // Execute the verification command
            vm.ffi(cmd);
        }
    }
}
