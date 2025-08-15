// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/PalStorage.sol";
import "../src/PalCore.sol";
import "../src/PalGovernance.sol";

contract DeployPAL is Script {
    function run() external {
        // Load private key from environment variable
        string memory privateKeyStr = vm.envString("AVALANCHE_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying with address:", deployer);
        console.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Data Storage
        PALDataStorage dataStorage = new PALDataStorage();
        console.log("PALDataStorage deployed at:", address(dataStorage));
        
        // Deploy PAL Core
        PALCore palCore = new PALCore(address(dataStorage));
        console.log("PALCore deployed at:", address(palCore));
        
        // Deploy Governance (upgradeable)
        PALGovernance governance = new PALGovernance();
        governance.initialize(); // Initialize with deployer as owner
        console.log("PALGovernance deployed at:", address(governance));
        
        vm.stopBroadcast();
    }
}