// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PalCore.sol";

/**
 * @title PAL Deployment Script
 * @notice Scripts for deploying PAL contracts to Base networks
 * @dev Handles both testnet and mainnet deployments
 */
contract PALDeployScript is Script {
    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address teamWallet = vm.envAddress("TEAM_WALLET");

        vm.startBroadcast(deployerPrivateKey);

        PalCore pal = new PalCore(teamWallet);

        vm.stopBroadcast();

        // Log deployment details
        console.log("PAL contract deployed at:", address(pal));
        console.log("Transaction Manager:", address(pal.transactionManager()));
        console.log("Project Tracker:", address(pal.projectTracker()));
        console.log("Team Wallet:", pal.teamWallet());
    }
}

/**
 * @title Base Sepolia Deployment Script
 * @notice Specific deployment script for Base Sepolia testnet
 */
contract DeployBaseSepolia is PALDeployScript {
    function run() public override {
        // Set up Base Sepolia specific parameters
        uint256 deployNetwork = vm.envUint("DEPLOY_NETWORK");
        require(
            block.chainid == 84532 || deployNetwork == 84532,
            "Wrong network for Base Sepolia"
        );
        PALDeployScript.run();
    }
}

/**
 * @title Base Mainnet Deployment Script
 * @notice Specific deployment script for Base mainnet
 */
contract DeployBaseMainnet is PALDeployScript {
    function run() public override {
        // Set up Base Mainnet specific parameters
        uint256 deployNetwork = vm.envUint("DEPLOY_NETWORK");
        require(
            block.chainid == 8453 || deployNetwork == 8453,
            "Wrong network for Base Mainnet"
        );
        PALDeployScript.run();
    }
}
