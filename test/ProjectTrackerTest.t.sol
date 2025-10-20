// SPDX-License-Identifier: MIT

import {Test} from "forge-std/Test.sol";
import {ProjectTracker} from "../src/ProjectTracker.sol";
import {DeployProjectTracker} from "../script/DeployProjectTracker.s.sol";

pragma solidity ^0.8.26;

contract ProjectTrackerTest is Test {
    ProjectTracker public contractInstance;
    DeployProjectTracker public deployer;
    function setUp() public {
        deployer = new DeployProjectTracker();
        contractInstance = deployer.run();

    }

    function testExample() public {
        // Add your test logic here
    }
}