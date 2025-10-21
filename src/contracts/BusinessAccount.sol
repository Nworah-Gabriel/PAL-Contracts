// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IBusinessAccount} from "@interface/IBusinessAccount.sol";
import {IPAL} from "@interface/IPal.sol";

/**
 * @author Nworah Chimzuruoke Gabriel (SAGGIO)
 * @title Business Account Contract
 * @notice Individual business account storage and management
 * @dev Each business gets its own contract instance
 */
contract BusinessAccount is IBusinessAccount {
    // Business information
    uint256 public immutable businessId;
    address public immutable owner;
    string public businessName;
    string public businessType;
    uint256 public createdAt;

    /**
     * @dev Constructor to initialize business account
     * @param _businessId Unique business ID
     * @param _owner Business owner address
     * @param _name Business name
     * @param _businessType Type of business
     */
    constructor(
        uint256 _businessId,
        address _owner,
        string memory _name,
        string memory _businessType
    ) {
        require(_owner != address(0), "BusinessAccount: owner cannot be zero");
        require(bytes(_name).length > 0, "BusinessAccount: name required");
        require(
            bytes(_businessType).length > 0,
            "BusinessAccount: type required"
        );

        businessId = _businessId;
        owner = _owner;
        businessName = _name;
        businessType = _businessType;
        createdAt = block.timestamp;
    }

    /**
     * @notice Updates business information
     * @dev Only callable by business owner
     * @param _name New business name
     * @param _businessType New business type
     */
    function updateBusinessInfo(
        string calldata _name,
        string calldata _businessType
    ) external override {
        require(msg.sender == owner, "BusinessAccount: owner only");
        require(bytes(_name).length > 0, "BusinessAccount: name required");
        require(
            bytes(_businessType).length > 0,
            "BusinessAccount: type required"
        );

        businessName = _name;
        businessType = _businessType;

        emit BusinessInfoUpdated(
            businessId,
            _name,
            _businessType,
            block.timestamp
        );
    }

    /**
     * @notice Gets complete business information
     * @return Business account information struct
     */
    function getBusinessInfo()
        external
        view
        override
        returns (IPAL.BusinessAccountInfo memory)
    {
        return
            IPAL.BusinessAccountInfo({
                businessId: businessId,
                owner: owner,
                businessName: businessName,
                businessType: businessType,
                createdAt: createdAt
            });
    }
}
