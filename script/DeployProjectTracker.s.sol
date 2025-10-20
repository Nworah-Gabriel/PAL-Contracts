// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ProjectTracker} from "../src/ProjectTracker.sol";

pragma solidity ^0.8.26;

contract DeployProjectTracker is Script {
    function run() external returns (ProjectTracker) {
        vm.startBroadcast();
        ProjectTracker constract = new ProjectTracker();
        console2.log(" contract address", address(constract));
        vm.stopBroadcast();
        return constract;
    }
}