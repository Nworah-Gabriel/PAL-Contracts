// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPAL} from "@interface/IPal.sol";

interface IBusinessAccount {
    event BusinessInfoUpdated(
        uint256 indexed businessId,
        string businessName,
        string businessType,
        uint256 timestamp
    );

    function updateBusinessInfo(
        string calldata _name,
        string calldata _businessType
    ) external;

    function getBusinessInfo()
        external
        view
        returns (IPAL.BusinessAccountInfo memory);
}
