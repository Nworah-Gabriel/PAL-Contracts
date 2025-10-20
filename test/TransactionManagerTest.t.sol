// SPDX-License-Identifier: MIT

import {Test} from "forge-std/Test.sol";
import {TransactionManager} from "../src/TransactionManager.sol";
import {DeployTransactionManager} from "../script/DeployTransactionManager.s.sol";

pragma solidity ^0.8.26;

contract TransactionManagerTest is Test {
    TransactionManager public contractInstance;
    DeployTransactionManager public deployer;
    function setUp() public {
        deployer = new DeployTransactionManager();
        contractInstance = deployer.run();

    }

    function testExample() public {
        // Add your test logic here
    }
}