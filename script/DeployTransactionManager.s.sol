// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {TransactionManager} from "../src/TransactionManager.sol";

pragma solidity ^0.8.26;

contract DeployTransactionManager is Script {
    function run() external returns (TransactionManager) {
        vm.startBroadcast();
        TransactionManager constract = new TransactionManager();
        console2.log(" contract address", address(constract));
        vm.stopBroadcast();
        return constract;
    }
}